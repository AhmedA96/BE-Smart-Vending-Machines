################################################################################
# Cloudflare R2 Storage Configuration
#
# R2 buckets for:
# 1. Application backups (database snapshots, logs)
# 2. Media/assets storage (product images, reports, etc.)
# 3. Lifecycle management and versioning
#
# Advantages over S3:
# - No egress charges (10x cheaper than S3)
# - S3-compatible API
# - Built-in CDN (Cloudflare)
# - Better pricing for high-volume storage
################################################################################

# ==============================================================================
# 1. Terraform Provider for Cloudflare
# ==============================================================================
# Add this to providers.tf or configure via environment variables:
#
# terraform {
#   required_providers {
#     cloudflare = {
#       source  = "cloudflare/cloudflare"
#       version = "~> 4.0"
#     }
#   }
# }
#
# provider "cloudflare" {
#   api_token = var.cloudflare_api_token  # Set via TF_VAR_cloudflare_api_token
# }

# ==============================================================================
# 2. Application Backups Bucket
# ==============================================================================
# Stores database snapshots, RDS backups, and application logs

resource "aws_s3_bucket" "app_backups" {
  # Using S3-compatible endpoint for R2
  # Configured via environment variable or terraform.tfvars:
  # AWS_ACCESS_KEY_ID = Cloudflare R2 Access Key ID
  # AWS_SECRET_ACCESS_KEY = Cloudflare R2 Secret Access Key
  # AWS_ENDPOINT_URL_S3 = https://<account-id>.r2.cloudflarestorage.com

  bucket = "${var.project_name}-backups"

  tags = {
    Name        = "${var.project_name}-backups"
    Environment = var.environment
    Purpose     = "Database and application backups"
    Storage     = "Cloudflare R2"
  }
}

# Versioning for backup safety
resource "aws_s3_bucket_versioning" "app_backups" {
  bucket = aws_s3_bucket.app_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle rules for backup retention
resource "aws_s3_bucket_lifecycle_configuration" "app_backups" {
  bucket = aws_s3_bucket.app_backups.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.s3_version_retention_days
    }
  }

  rule {
    id     = "delete-old-backups"
    status = "Enabled"
    filter {}

    expiration {
      days = var.s3_backup_retention_days
    }
  }

  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.s3_incomplete_upload_cleanup_days
    }
  }
}

# ==============================================================================
# 3. Media/Assets Bucket
# ==============================================================================
# Stores application media (product images, receipts, reports, etc.)

resource "aws_s3_bucket" "app_media" {
  bucket = "${var.project_name}-media"

  tags = {
    Name        = "${var.project_name}-media"
    Environment = var.environment
    Purpose     = "Application media and assets"
    Storage     = "Cloudflare R2"
  }
}

# Versioning for media backup
resource "aws_s3_bucket_versioning" "app_media" {
  bucket = aws_s3_bucket.app_media.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle rules for media
resource "aws_s3_bucket_lifecycle_configuration" "app_media" {
  bucket = aws_s3_bucket.app_media.id

  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.s3_incomplete_upload_cleanup_days
    }
  }

  rule {
    id     = "delete-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.s3_backup_retention_days
    }
  }
}

# ==============================================================================
# 4. R2 Bucket Configuration (Alternative: Native R2 resources)
# ==============================================================================
# For native Cloudflare R2 management, use cloudflare provider:
#
# resource "cloudflare_r2_bucket" "app_backups" {
#   account_id = var.cloudflare_account_id
#   bucket     = "${var.project_name}-backups"
# }
#
# resource "cloudflare_r2_bucket" "app_media" {
#   account_id = var.cloudflare_account_id
#   bucket     = "${var.project_name}-media"
# }

# ==============================================================================
# 5. Credentials for R2 Access
# ==============================================================================
# Store in Secrets Manager for app/worker access:
#
# Manual setup:
#   1. Create R2 API token in Cloudflare dashboard
#   2. Store in AWS Secrets Manager:
#      {
#        "r2_access_key_id": "...",
#        "r2_secret_access_key": "...",
#        "r2_endpoint": "https://<account-id>.r2.cloudflarestorage.com",
#        "r2_bucket_backups": "vending-backups",
#        "r2_bucket_media": "vending-media"
#      }
#   3. App fetches via IAM role policy (already defined below)

# ==============================================================================
# 6. IAM Policy for App/Worker Access to R2
# ==============================================================================
# This policy is referenced in autoscaling_app.tf and autoscaling_worker.tf
# Applications use S3 SDK with R2 endpoint + credentials from Secrets Manager

resource "aws_iam_policy" "app_s3_access" {
  name_prefix = "${var.project_name}-app-r2-access-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerR2Credentials"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/r2/*"
      },
      {
        Sid    = "KMSDecryptR2Credentials"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-app-r2-access"
  }

  depends_on = [data.aws_caller_identity.current]
}

# ==============================================================================
# 7. IAM Policy for CloudWatch Logs
# ==============================================================================
# Allows app and worker servers to write logs to CloudWatch

resource "aws_iam_policy" "app_cloudwatch" {
  name_prefix = "${var.project_name}-app-cloudwatch-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CreateLogGroup"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/${var.project_name}*"
      },
      {
        Sid    = "PutMetricData"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = var.project_name
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-app-cloudwatch"
  }

  depends_on = [data.aws_caller_identity.current]
}

# ==============================================================================
# 8. IAM Policy for Secrets Manager Access
# ==============================================================================
# Allows app and worker servers to read secrets (DB, Redis, R2 credentials)

resource "aws_iam_policy" "app_secrets_read" {
  name_prefix = "${var.project_name}-app-secrets-read-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/*"
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-app-secrets-read"
  }

  depends_on = [data.aws_caller_identity.current]
}

# ==============================================================================
# 9. Data Source for AWS Account ID
# ==============================================================================

data "aws_caller_identity" "current" {}

# ==============================================================================
# Outputs
# ==============================================================================

output "r2_backup_bucket" {
  description = "Cloudflare R2 bucket for application backups"
  value       = aws_s3_bucket.app_backups.id
}

output "r2_media_bucket" {
  description = "Cloudflare R2 bucket for application media"
  value       = aws_s3_bucket.app_media.id
}

output "app_r2_policy_arn" {
  description = "ARN of R2 access policy for app/worker servers"
  value       = aws_iam_policy.app_s3_access.arn
}

output "app_cloudwatch_policy_arn" {
  description = "ARN of CloudWatch policy for app/worker servers"
  value       = aws_iam_policy.app_cloudwatch.arn
}

output "app_secrets_policy_arn" {
  description = "ARN of Secrets Manager policy for app/worker servers"
  value       = aws_iam_policy.app_secrets_read.arn
}

# ==============================================================================
# Setup Instructions for R2
# ==============================================================================
#
# 1. CREATE R2 BUCKET IN CLOUDFLARE DASHBOARD:
#    - Go to Cloudflare Dashboard → R2
#    - Create bucket: vending-backups
#    - Create bucket: vending-media
#
# 2. GENERATE R2 API TOKEN:
#    - R2 Settings → API Tokens → Create API Token
#    - Choose: Edit (for uploads/downloads)
#    - Scope: All buckets or specific buckets
#    - Save Access Key ID and Secret Access Key
#
# 3. STORE IN AWS SECRETS MANAGER:
#    aws secretsmanager create-secret \
#      --name vending/r2 \
#      --secret-string '{
#        "r2_access_key_id": "YOUR_KEY_ID",
#        "r2_secret_access_key": "YOUR_SECRET_KEY",
#        "r2_endpoint": "https://ACCOUNT_ID.r2.cloudflarestorage.com",
#        "r2_bucket_backups": "vending-backups",
#        "r2_bucket_media": "vending-media"
#      }' \
#      --region me-south-1
#
# 4. CONFIGURE IN APPLICATION:
#    # In your Rails initializer (config/initializers/aws.rb):
#    
#    r2_config = Rails.application.secrets.r2 || {}
#    
#    Aws.config.update(
#      access_key_id: r2_config['r2_access_key_id'],
#      secret_access_key: r2_config['r2_secret_access_key'],
#      region: 'auto',
#      endpoint: r2_config['r2_endpoint'],
#      s3_force_path_style: true,
#    )
#
# 5. USE WITH RUBY GEMS:
#    # Gemfile:
#    gem 'aws-sdk-s3'
#    
#    # Usage:
#    s3_client = Aws::S3::Client.new
#    s3_client.put_object(
#      bucket: r2_config['r2_bucket_media'],
#      key: "images/product-123.jpg",
#      body: file_content
#    )
#
# COST COMPARISON:
# S3:  $0.023/GB egress + storage fees = ~$23/TB egress + $23/TB storage
# R2:  $0.000/GB egress + $0.015/GB storage = ~$15/TB storage only
#      Savings: ~$8/TB + free egress = 66% cheaper for high-volume apps
#
# ==============================================================================
