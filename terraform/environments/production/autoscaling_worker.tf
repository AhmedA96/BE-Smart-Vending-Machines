################################################################################
# Auto Scaling Group for Worker Servers - SINGLE INSTANCE CONFIGURATION
#
# Updated to run only 1 worker server instance for cost optimization.
# Changes made:
# - min_size = 1, max_size = 1, desired_capacity = 1
# - Disabled auto-scaling policies (not needed for single instance)
# - Kept health checks for automatic recovery if instance fails
################################################################################

# ==============================================================================
# 1. IAM Role for Worker Instances
# ==============================================================================

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
  key_name               = "vending-system-prod"
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

  # User data script - install Docker and prepare for Kamal deployment
  user_data = base64encode(templatefile("${path.module}/worker_init.sh", {
    environment = var.environment
    aws_region  = var.aws_region
  }))

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
# 3. Auto Scaling Group for Workers - SINGLE INSTANCE
# ==============================================================================

resource "aws_autoscaling_group" "worker" {
  name_prefix         = "worker-"
  vpc_zone_identifier = [aws_subnet.private_app_1.id] # Single subnet only

  min_size         = var.worker_min_capacity
  max_size         = var.worker_max_capacity
  desired_capacity = var.worker_desired_capacity

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

  # Health checks: Use EC2 status checks (no load balancer)
  health_check_type         = "EC2"
  health_check_grace_period = 600 # 10 minutes (time for Docker init to complete)

  # Termination policies
  termination_policies = [
    "OldestLaunchTemplate",
    "Default"
  ]

  # Instance refresh
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0 # Allow full replacement for single instance
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
# 4. Scaling Policies - DISABLED FOR SINGLE INSTANCE
# ==============================================================================
# All scaling policies and CloudWatch alarms removed.
# Single instance will process all background jobs.
# If queue depth becomes too high, you'll need to manually increase capacity
# or implement queue-depth monitoring alerts.

# ==============================================================================
# Single Worker Instance Notes
# ==============================================================================
#
# CHANGES FROM MULTI-INSTANCE SETUP:
# ✓ min_size = 1, max_size = 1, desired_capacity = 1
# ✓ Removed all auto-scaling policies
# ✓ Removed CloudWatch alarms for scaling
# ✓ Uses single subnet only
# ✓ min_healthy_percentage = 0 for instance refresh
#
# WHAT STILL WORKS:
# ✓ Automatic instance replacement if health check fails
# ✓ EC2 health checks
# ✓ Rolling updates via instance refresh
# ✓ CloudWatch monitoring
# ✓ SSM Session Manager access
# ✓ Background job processing
#
# TRADE-OFFS:
# ✓ Reduced cost: ~50-80% savings on worker EC2 costs
# ✗ No horizontal scaling during high job volume
# ✗ Jobs may queue up during peak times
# ✗ Brief processing pause during instance replacement
# ✗ Single point of failure for background jobs
#
# MONITORING RECOMMENDATIONS:
# - Set up CloudWatch alarm for high Redis queue depth
# - Alert when queue > 1000 jobs
# - Monitor job processing rate
# - Track failed job count
#
# WHEN TO SCALE BACK TO MULTIPLE WORKERS:
# - Consistent queue depth > 500 jobs
# - Job processing time > 5 minutes per job
# - Critical time-sensitive background jobs
# - High job failure rate due to timeouts
#
# COST IMPACT:
# Before: 2-5 workers × $30/month = $60-150/month
# After:  1 worker × $30/month = $30/month
# Savings: $30-120/month (~50-80%)
#
# ==============================================================================