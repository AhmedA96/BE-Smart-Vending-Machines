terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ============================================================================
  # REMOTE STATE CONFIGURATION
  # ============================================================================
  # 
  # After running bootstrap (terraform/bootstrap), uncomment this block:
  #
  # Usage:
  #   1. cd ../../bootstrap && terraform apply
  #   2. Copy the state_bucket_name and dynamodb_table_name from outputs
  #   3. Uncomment and update this block with those values
  #   4. terraform init -migrate-state
  #
  # backend "s3" {
  #   bucket         = "vndg-terraform-state-YOUR_ACCOUNT_ID" # Run bootstrap first
  #   key            = "production/terraform.tfstate"
  #   region         = "me-central-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}
