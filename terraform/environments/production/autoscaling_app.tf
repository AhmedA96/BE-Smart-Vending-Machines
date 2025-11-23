################################################################################
# Auto Scaling Group for Application Servers
#
# This configuration creates a Launch Template and Auto Scaling Group
# that automatically scales app servers based on CPU utilization.
#
# Key features:
# - Launch template with security group, IAM role, and user data script
# - Auto Scaling Group with min/max/desired capacity
# - Scaling policies based on CPU utilization
# - Target group attachment for load balancer
# - Termination policies for graceful replacement
################################################################################

# ==============================================================================
# 1. IAM Role for EC2 Instances
# ==============================================================================
# Allows app servers to:
# - Read secrets from AWS Secrets Manager
# - Access S3 for backups/storage
# - CloudWatch logs
# - Systems Manager Session Manager (SSM)

resource "aws_iam_role" "app_role" {
  name_prefix = "${var.project_name}-app-role-"

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
    Name = "${var.project_name}-app-role"
  }
}

# Attach the secrets access policy (defined in storage.tf)
resource "aws_iam_role_policy_attachment" "app_secrets" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.app_secrets_read.arn
}

# Attach R2/S3 access policy (defined in storage.tf)
resource "aws_iam_role_policy_attachment" "app_s3" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.app_s3_access.arn
}

# Attach CloudWatch policy (defined in storage.tf)
resource "aws_iam_role_policy_attachment" "app_cloudwatch" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.app_cloudwatch.arn
}

# SSM Session Manager (for secure SSH access)
resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile to attach role to EC2
resource "aws_iam_instance_profile" "app_profile" {
  name_prefix = "${var.project_name}-app-profile-"
  role        = aws_iam_role.app_role.name
}

# ==============================================================================
# 2. Launch Template (EC2 Configuration Blueprint)
# ==============================================================================
# Defines how app server instances are launched

resource "aws_launch_template" "app" {
  name_prefix            = "app-"
  image_id               = data.aws_ami.ubuntu.id # Ubuntu 22.04 LTS
  instance_type          = var.app_instance_type
  key_name               = "vending-system-prod" # SSH keypair for Kamal deployment
  vpc_security_group_ids = [aws_security_group.app.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }

  # Block device configuration for launch template
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type           = var.app_ebs_volume_type
      volume_size           = var.app_ebs_volume_size
      delete_on_termination = true
      encrypted             = true
    }
  }

  # Monitoring
  monitoring {
    enabled = true
  }

  # User data script - install Docker and prepare for Kamal deployment
  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              
              echo "Initializing app server..."
              echo "Environment: ${var.environment}"
              echo "Region: ${var.aws_region}"
              
              # Install Docker
              echo "Installing Docker..."
              curl -fsSL https://get.docker.com -o get-docker.sh
              sh get-docker.sh
              rm get-docker.sh
              
              # Add ubuntu user to docker group (required for Kamal deployment)
              echo "Configuring Docker permissions..."
              usermod -aG docker ubuntu
              
              echo "App server initialization complete"
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app-server"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.project_name}-app-volume"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_iam_instance_profile.app_profile,
    aws_security_group.app
  ]
}

# ==============================================================================
# 3. Auto Scaling Group
# ==============================================================================
# Automatically launches/terminates instances based on demand

resource "aws_autoscaling_group" "app" {
  name_prefix         = "app-"
  vpc_zone_identifier = [aws_subnet.private_app_1.id, aws_subnet.private_app_2.id]

  min_size         = var.app_min_capacity
  max_size         = var.app_max_capacity
  desired_capacity = var.app_desired_capacity

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app.arn]

  # Health check configuration
  health_check_type         = "ELB" # Use ALB health checks
  health_check_grace_period = 600   # 10 minutes (time for Kamal setup to complete)

  # Termination policies
  termination_policies = [
    "OldestLaunchTemplate",
    "Default"
  ]

  # Enable capacity rebalancing (for Spot instances in future)
  capacity_rebalance = false

  # Instance refresh (for rolling updates)
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-server"
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
    aws_launch_template.app,
    aws_lb_target_group.app,
    aws_rds_cluster_instance.primary,
    aws_elasticache_replication_group.redis
  ]
}

# ==============================================================================
# 4. Scaling Policies
# ==============================================================================

# Scale UP when CPU > 70%
resource "aws_autoscaling_policy" "app_scale_up" {
  name                   = "${var.project_name}-app-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300 # 5 minutes between scale events
  autoscaling_group_name = aws_autoscaling_group.app.name
}

# Scale DOWN when CPU < 30%
resource "aws_autoscaling_policy" "app_scale_down" {
  name                   = "${var.project_name}-app-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

# CloudWatch Alarm: Scale UP
resource "aws_cloudwatch_metric_alarm" "app_scale_up_alarm" {
  alarm_name          = "${var.project_name}-app-scale-up-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300" # 5 minutes
  statistic           = "Average"
  threshold           = tostring(var.app_scale_up_cpu_threshold)
  alarm_description   = "Scale up when CPU > ${var.app_scale_up_cpu_threshold}%"
  alarm_actions       = [aws_autoscaling_policy.app_scale_up.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  depends_on = [aws_autoscaling_policy.app_scale_up]
}

# CloudWatch Alarm: Scale DOWN
resource "aws_cloudwatch_metric_alarm" "app_scale_down_alarm" {
  alarm_name          = "${var.project_name}-app-scale-down-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "4" # More evaluations before scaling down
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = tostring(var.app_scale_down_cpu_threshold)
  alarm_description   = "Scale down when CPU < ${var.app_scale_down_cpu_threshold}%"
  alarm_actions       = [aws_autoscaling_policy.app_scale_down.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  depends_on = [aws_autoscaling_policy.app_scale_down]
}

# ==============================================================================
# 5. Data Source: Ubuntu AMI
# ==============================================================================
# Automatically fetches latest Ubuntu 22.04 LTS AMI

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==============================================================================
# App Server Auto Scaling Notes
# ==============================================================================
#
# LAUNCH TEMPLATE:
# - Defines how instances are launched
# - Includes security groups, IAM roles, user data
# - Can be versioned for rolling updates
# - Launch template used instead of Launch Configuration
#   (Launch Configuration is deprecated)
#
# AUTO SCALING GROUP:
# - Launches instances from template
# - Maintains desired capacity
# - Replaces unhealthy instances
# - Distributes across multiple subnets (AZs)
# - Attaches instances to target group
#
# HEALTH CHECKS:
# - Type: ELB (use load balancer health checks)
# - Grace period: 300 seconds (5 minutes)
# - Time for instance to boot and become healthy
# - If health check fails 3x, instance is replaced
#
# SCALING POLICIES:
# - Scale UP when CPU > 70% for 2 periods (10 minutes)
# - Scale DOWN when CPU < 30% for 4 periods (20 minutes)
# - Cooldown prevents rapid scaling
# - Min: 2, Max: 4, can scale to 1 instance if needed
#
# TERMINATION POLICIES:
# - OldestLaunchTemplate: Remove instances with old launch template
# - Default: Balanced termination
# - Ensures rolling updates work smoothly
#
# INSTANCE REFRESH:
# - Rolling updates: Replace instances gradually
# - Min healthy percentage: 50% (keep at least 1 instance healthy)
# - Useful for deployments without downtime
#
# IAM ROLE PERMISSIONS:
# - Secrets Manager: Read database/Redis/app credentials
# - S3: Read/write external storage
# - CloudWatch: Write logs
# - SSM: Session Manager (for SSH without key pairs)
#
# USER DATA SCRIPT (user_data_app.sh):
# - Runs on instance startup
# - Updates packages
# - Installs Docker (if using containers)
# - Pulls application code
# - Starts application server
# - Configures logging
#
# ==============================================================================
# Deployment Strategy (Future)
# ==============================================================================
#
# Blue-Green Deployment:
# 1. Create new launch template version (Green)
# 2. Create new ASG with Green template
# 3. Update load balancer target group
# 4. Verify Green is healthy
# 5. Delete Blue ASG
#
# Rolling Deployment (Current):
# 1. Update launch template
# 2. Trigger instance refresh
# 3. ASG replaces instances one by one
# 4. Load balancer keeps healthy instance in rotation
# 5. Zero downtime (if min 2 instances)
#
# Canary Deployment:
# 1. Route 5% of traffic to new version
# 2. Monitor for errors
# 3. Gradually increase traffic
# 4. Full rollout or rollback
#
# ==============================================================================
# Monitoring & Debugging
# ==============================================================================
#
# Key metrics to monitor:
# - GroupDesiredCapacity: Desired vs actual instances
# - GroupInServiceInstances: Healthy instances
# - GroupPendingInstances: Starting up
# - GroupTerminatingInstances: Shutting down
# - GroupTotalInstances: Total across all states
#
# Common issues:
# - Instances failing health check:
#   → Check /up endpoint
#   → Verify security groups allow ALB → App
#   → Check application logs
#
# - Scaling not happening:
#   → Check CloudWatch alarms
#   → Verify CPU metrics are being reported
#   → Check ASG cooldown
#
# - Stuck in pending:
#   → Check IAM role permissions
#   → Verify subnet has available IPs
#   → Check security group allows required traffic
#

