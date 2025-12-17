################################################################################
# Bootstrap Terraform Configuration
#
# This creates the remote state infrastructure (S3 + DynamoDB) automatically
# Run this FIRST before deploying the main infrastructure
#
# Usage:
#   cd terraform/bootstrap
#   terraform init
#   terraform plan
#   terraform apply
#   cd ..
#   terraform init -migrate-state  # Migrate to remote state
#   terraform plan
#   terraform apply
#
################################################################################

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Bootstrap uses local state - this is intentional and safe
  # After bootstrap completes, main infrastructure will use remote state
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "terraform-bootstrap"
      ManagedBy   = "Terraform"
    }
  }
}

################################################################################
# 1. S3 Bucket for Terraform State
################################################################################

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.state_bucket_prefix}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-terraform-state"
    Description = "Remote state storage for Terraform"
  }
}

# Enable versioning for state rollback capability
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for security
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable access logging for audit trail
resource "aws_s3_bucket" "terraform_logs" {
  bucket = "${var.state_bucket_prefix}-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-terraform-logs"
    Description = "Access logs for Terraform state bucket"
  }
}

resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.terraform_logs.id
  target_prefix = "state-access-logs/"

  depends_on = [aws_s3_bucket_public_access_block.terraform_logs]
}

resource "aws_s3_bucket_public_access_block" "terraform_logs" {
  bucket = aws_s3_bucket.terraform_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################################
# 2. DynamoDB Table for State Locking
################################################################################

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-terraform-locks"
    Description = "State locking table for Terraform"
  }
}

################################################################################
# 3. Data Sources
################################################################################

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
