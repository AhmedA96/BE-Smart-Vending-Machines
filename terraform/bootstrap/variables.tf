################################################################################
# Bootstrap Variables
################################################################################

variable "aws_region" {
  description = "AWS region for remote state infrastructure"
  type        = string
  default     = "me-south-1"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "vending-system"
}

variable "state_bucket_prefix" {
  description = "Prefix for S3 state bucket (account ID will be appended)"
  type        = string
  default     = "vndg-terraform-state"
}

variable "dynamodb_table_name" {
  description = "Name of DynamoDB table for state locking"
  type        = string
  default     = "terraform-locks"
}
