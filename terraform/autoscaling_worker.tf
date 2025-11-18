################################################################################
# Auto Scaling Group for Worker Servers
#
# Worker servers process background jobs from Redis queue.
# This configuration creates a separate ASG for workers with different
# scaling policies (based on queue depth instead of CPU).
#
# Key differences from app servers:
# - Not behind load balancer
# - Scales based on Redis queue depth
# - Processes async jobs (long-running tasks)
# - Can tolerate longer startup time
################################################################################

# ==============================================================================
# 1. IAM Role for Worker Instances
# ==============================================================================
# Similar to app servers but may not need all permissions

resource "aws_iam_role" "worker_role" {
  name_prefix = "${var.project_name}-worker-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-worker-role"
  }
}

# Attach secrets access policy (defined in storage.tf)
resource "aws_iam_role_policy_attachment" "worker_secrets" {
  role       = aws_iam_role.worker_role.name
  policy_arn = aws_iam_policy.app_secrets_read.arn
}

# Attach R2/S3 access policy (defined in storage.tf)
resource "aws_iam_role_policy_attachment" "worker_s3" {
  role       = aws_iam_role.worker_role.name
  policy_arn = aws_iam_policy.app_s3_access.arn
}

# Attach CloudWatch policy (defined in storage.tf)
resource "aws_iam_role_policy_attachment" "worker_cloudwatch" {
  role       = aws_iam_role.worker_role.name
  policy_arn = aws_iam_policy.app_cloudwatch.arn
}

# SSM Session Manager
resource "aws_iam_role_policy_attachment" "worker_ssm" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "worker_profile" {
  name_prefix = "${var.project_name}-worker-profile-"
  role        = aws_iam_role.worker_role.name
}

# ==============================================================================
# 2. Launch Template for Workers
# ==============================================================================

resource "aws_launch_template" "worker" {
  name_prefix            = "worker-"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  vpc_security_group_ids = [aws_security_group.app.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.worker_profile.name
  }

  # Block device configuration for launch template
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type           = var.worker_ebs_volume_type
      volume_size           = var.worker_ebs_volume_size
      delete_on_termination = true
      encrypted             = true
    }
  }

  # Monitoring
  monitoring {
    enabled = true
  }

  # User data script - basic startup configuration
  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              echo "Initializing worker server..."
              echo "Environment: ${var.environment}"
              echo "Region: ${var.aws_region}"
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-worker-server"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_iam_instance_profile.worker_profile,
    aws_security_group.app
  ]
}

# ==============================================================================
# 3. Auto Scaling Group for Workers
# ==============================================================================

resource "aws_autoscaling_group" "worker" {
  name_prefix         = "worker-"
  vpc_zone_identifier = [aws_subnet.private_app_1.id, aws_subnet.private_app_2.id]

  min_size         = var.worker_min_capacity
  max_size         = var.worker_max_capacity
  desired_capacity = var.worker_desired_capacity

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

  # Health checks: Use EC2 status checks (no load balancer)
  health_check_type         = "EC2"
  health_check_grace_period = 300 # 5 minutes for startup

  # Termination policies
  termination_policies = [
    "OldestLaunchTemplate",
    "Default"
  ]

  # Instance refresh
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-worker-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_launch_template.worker,
    aws_security_group.app
  ]
}

# ==============================================================================
# 4. Scaling Policies - CPU Based (Simple)
# ==============================================================================
# Note: For production, implement queue-depth-based scaling

# Scale UP when CPU > 60%
resource "aws_autoscaling_policy" "worker_scale_up" {
  name                   = "${var.project_name}-worker-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.worker.name
}

# Scale DOWN when CPU < 20%
resource "aws_autoscaling_policy" "worker_scale_down" {
  name                   = "${var.project_name}-worker-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.worker.name
}

# CloudWatch Alarm: Scale UP
resource "aws_cloudwatch_metric_alarm" "worker_scale_up_alarm" {
  alarm_name          = "${var.project_name}-worker-scale-up-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = tostring(var.worker_scale_up_cpu_threshold)
  alarm_description   = "Scale up workers when CPU > ${var.worker_scale_up_cpu_threshold}%"
  alarm_actions       = [aws_autoscaling_policy.worker_scale_up.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.worker.name
  }
}

# CloudWatch Alarm: Scale DOWN
resource "aws_cloudwatch_metric_alarm" "worker_scale_down_alarm" {
  alarm_name          = "${var.project_name}-worker-scale-down-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "4"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = tostring(var.worker_scale_down_cpu_threshold)
  alarm_description   = "Scale down workers when CPU < ${var.worker_scale_down_cpu_threshold}%"
  alarm_actions       = [aws_autoscaling_policy.worker_scale_down.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.worker.name
  }
}

# ==============================================================================
# 5. Custom Metric: Queue Depth (Future Enhancement)
# ==============================================================================
# For production, implement queue depth monitoring:
#
# In your worker code, periodically publish queue depth to CloudWatch:
#
# aws cloudwatch put-metric-data \
#   --namespace VendingSystem \
#   --metric-name RedisQueueDepth \
#   --value <queue_length> \
#   --unit Count \
#   --region me-south-1
#
# Then create scaling policy based on queue depth:
#
# resource "aws_autoscaling_policy" "worker_scale_up_queue" {
#   name                   = "${var.project_name}-worker-scale-up-queue"
#   autoscaling_group_name = aws_autoscaling_group.worker.name
#   policy_type            = "TargetTrackingScaling"
#
#   target_tracking_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ASGAverageCPUUtilization"
#     }
#     target_value = 0.7
#   }
# }
#
# Or use custom metrics:
#
# resource "aws_autoscaling_policy" "worker_queue_based" {
#   name                   = "${var.project_name}-worker-queue-based"
#   autoscaling_group_name = aws_autoscaling_group.worker.name
#   policy_type            = "TargetTrackingScaling"
#
#   target_tracking_configuration {
#     customized_metric_specification {
#       metric_name = "RedisQueueDepth"
#       namespace   = "VendingSystem"
#       statistic   = "Average"
#     }
#     target_value = 100  # Jobs per worker
#   }
# }

# ==============================================================================
# Worker Scaling Strategy Notes
# ==============================================================================
#
# DIFFERENCES FROM APP SERVERS:
# 1. Not behind ALB (no target group)
# 2. No health checks from ALB (uses EC2 status checks)
# 3. Longer startup time acceptable (background jobs not time-critical)
# 4. Should scale based on queue depth, not CPU
#
# CURRENT IMPLEMENTATION:
# - CPU-based scaling (simple, no external monitoring needed)
# - Scale up at 60% CPU (more aggressive than app servers)
# - Scale down at 20% CPU (allow to cool off before removing)
# - Min: 2, Max: 5
#
# FUTURE IMPROVEMENTS:
# 1. Publish queue depth to CloudWatch custom metric
# 2. Scale based on queue depth (jobs/worker ratio)
# 3. Target: 100 jobs per worker in queue
# 4. Minimum 1 job per worker to keep processing
#
# IMPLEMENTATION:
# In your worker process (Sidekiq, Resque, etc.):
#   - Get queue length: LLEN vending_queue
#   - Divide by workers: jobs_per_worker = queue_length / num_workers
#   - If jobs_per_worker > 100: scale up
#   - If jobs_per_worker < 10: scale down
#
# COST IMPACT:
# - With queue-depth scaling: Better resource utilization
# - With CPU scaling: Simpler to implement
# - Balance: Start with CPU, add queue-depth scaling in Phase 2
#
# ==============================================================================

