################################################################################
# Auto Scaling Group for Application Servers - SINGLE INSTANCE CONFIGURATION
#
# Updated to run only 1 application server instance for cost optimization.
# Changes made:
# - min_size = 1, max_size = 1, desired_capacity = 1
# - Disabled auto-scaling policies (not needed for single instance)
# - Kept health checks for automatic recovery if instance fails
################################################################################

# ==============================================================================
# 1. IAM Role for EC2 Instances
# ==============================================================================

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
              # App Server Initialization Script
              # Sets up Docker and prepares for Kamal web deployment
              # This runs on EC2 instance startup to configure the app server
              
              set -e
              
              # Log all output
              exec > >(tee -a /var/log/app-init.log)
              exec 2>&1
              
              echo "=========================================="
              echo "Initializing app server..."
              echo "Environment: ${var.environment}"
              echo "Region: ${var.aws_region}"
              echo "=========================================="
              
              # Update system packages
              echo "[1/5] Updating system packages..."
              apt-get update
              apt-get upgrade -y
              
              # Install required dependencies
              echo "[2/5] Installing dependencies..."
              apt-get install -y \
                curl \
                wget \
                git \
                ca-certificates \
                gnupg \
                lsb-release \
                apt-transport-https \
                software-properties-common \
                jq \
                awscli
              
              # Install Docker
              echo "[3/5] Installing Docker..."
              curl -fsSL https://get.docker.com -o get-docker.sh
              sh get-docker.sh
              rm get-docker.sh
              
              # Add ubuntu user to docker group (required for Kamal deployment)
              # This fix resolves: "permission denied while trying to connect to docker API"
              # See: docs/DEPLOYMENT_TROUBLESHOOTING.md - Issue 1
              echo "[4/5] Configuring Docker permissions..."
              usermod -aG docker ubuntu
              
              # Start Docker daemon
              echo "[5/5] Starting Docker daemon..."
              systemctl enable docker
              systemctl start docker
              
              # Wait for Docker daemon to be ready
              echo "Waiting for Docker daemon to be ready..."
              for i in {1..30}; do
                if docker info &>/dev/null; then
                  echo "Docker daemon is ready"
                  break
                fi
                echo "Waiting... ($i/30)"
                sleep 1
              done
              
              echo "=========================================="
              echo "App server initialization complete!"
              echo "Docker is ready for Kamal deployment"
              echo "=========================================="
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
# 3. Auto Scaling Group - SINGLE INSTANCE
# ==============================================================================

resource "aws_autoscaling_group" "app" {
  name_prefix         = "app-"
  vpc_zone_identifier = [aws_subnet.private_app_1.id] # Single subnet only

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
  health_check_grace_period = 900   # 15 minutes (time for Docker init + app startup)

  # Termination policies
  termination_policies = [
    "OldestLaunchTemplate",
    "Default"
  ]

  capacity_rebalance = false

  # Instance refresh for updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0 # Allow full replacement for single instance
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
# 4. Scaling Policies - DISABLED FOR SINGLE INSTANCE
# ==============================================================================
# Scaling policies removed as they're not needed for single instance setup.
# The ASG will maintain exactly 1 instance and replace it if it fails.

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
# Single Instance Configuration Notes
# ==============================================================================
#
# CHANGES FROM MULTI-INSTANCE SETUP:
# ✓ min_size = 1, max_size = 1, desired_capacity = 1
# ✓ Removed auto-scaling policies (no CPU-based scaling)
# ✓ Removed CloudWatch alarms for scaling
# ✓ Uses single subnet only
# ✓ min_healthy_percentage = 0 for instance refresh
#
# WHAT STILL WORKS:
# ✓ Automatic instance replacement if health check fails
# ✓ Load balancer health checks
# ✓ Rolling updates via instance refresh
# ✓ CloudWatch monitoring
# ✓ SSM Session Manager access
#
# TRADE-OFFS:
# ✓ Reduced cost: ~50-75% savings on EC2 costs
# ✗ No horizontal scaling during traffic spikes
# ✗ Brief downtime during instance replacement/updates
# ✗ Single point of failure
#
# RECOMMENDED FOR:
# - Development environments
# - Staging environments
# - Low-traffic production (< 1000 requests/min)
# - Cost-sensitive deployments
#
# COST IMPACT:
# Before: 2-4 instances × $30/month = $60-120/month
# After:  1 instance × $30/month = $30/month
# Savings: $30-90/month (~50-75%)
#
# ==============================================================================