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
  # Bootstrap completed! Remote state configured.
  # State bucket: vndg-terraform-state-471112976287
  # DynamoDB table: terraform-locks
  #
  backend "s3" {
    bucket         = "vndg-terraform-state-471112976287"
    key            = "production/terraform.tfstate"
    region         = "me-central-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
