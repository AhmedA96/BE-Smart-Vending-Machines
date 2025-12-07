# ============================================
# BASTION HOST (Jumpbox)
# ============================================
# Bastion host in public subnet for SSH access to private app servers
# Used by Kamal for deployment
# Security: SSH key-based authentication (not IP-restricted)
# All team members with the SSH private key can access

# ==============================================================================
# 1. Security Group for Bastion
# ==============================================================================
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion"
  description = "Security group for bastion host - SSH access only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-bastion-sg"
  }
}

# Allow SSH inbound from anywhere
# Security relies on SSH key authentication, not IP whitelisting
resource "aws_security_group_rule" "bastion_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from anywhere (secured by SSH key authentication)"
}

# Allow SSH outbound to app servers
resource "aws_security_group_rule" "bastion_egress_app_ssh" {
  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.bastion.id
  description              = "SSH to app servers"
}

# Allow outbound HTTPS (for updates, etc)
resource "aws_security_group_rule" "bastion_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
  description       = "HTTPS outbound"
}

# ==============================================================================
# 2. IAM Role for Bastion (SSM access for debugging)
# ==============================================================================
resource "aws_iam_role" "bastion" {
  name = "${var.project_name}-bastion-role"

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
    Name = "${var.project_name}-bastion-role"
  }
}

# Attach SSM policy for Systems Manager Session Manager access
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.project_name}-bastion-profile"
  role = aws_iam_role.bastion.name
}

# ==============================================================================
# 3. Bastion EC2 Instance
# ==============================================================================
# Small t3.micro instance - minimal cost
# Ubuntu 24.04 LTS AMI
# Public IP for SSH access

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "vending-system-prod"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  # Enable public IP
  associate_public_ip_address = true

  # User data script for setup
  user_data = base64encode(templatefile("${path.module}/bastion_init.sh", {
    project_name = var.project_name
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring              = true
  disable_api_termination = false

  tags = {
    Name = "${var.project_name}-bastion"
  }

  depends_on = [aws_internet_gateway.main]
}

# ==============================================================================
# 4. Elastic IP for Bastion (Static Public IP)
# ==============================================================================
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-bastion-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# ==============================================================================
# 5. Allow App Servers to Accept SSH from Bastion
# ==============================================================================
# Update app server security group to allow SSH from bastion
resource "aws_security_group_rule" "app_ingress_bastion_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.app.id
  description              = "SSH from bastion"
}

# ============================================
# 6. Data Source for Ubuntu AMI (already defined in autoscaling_app.tf)
# ============================================
# Uses existing data.aws_ami.ubuntu from autoscaling_app.tf

# ============================================
# 7. CloudWatch Alarm for Bastion Health
# ============================================
resource "aws_cloudwatch_metric_alarm" "bastion_status_check" {
  alarm_name          = "${var.project_name}-bastion-status-check"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"

  dimensions = {
    InstanceId = aws_instance.bastion.id
  }

  alarm_description = "Alert if bastion instance status check fails"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-bastion-alarm"
  }
}
