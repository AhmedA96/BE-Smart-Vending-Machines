################################################################################
# Bootstrap Outputs
################################################################################

output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}

output "next_steps" {
  description = "Instructions for migrating to remote state"
  value       = <<-EOT
    
    ✅ Bootstrap complete! Remote state infrastructure created.
    
    NEXT STEPS:
    
    1. Configure main Terraform to use remote state:
       
       cd ..
       
       Edit main.tf and uncomment the backend "s3" block with:
       - bucket         = "${aws_s3_bucket.terraform_state.id}"
       - region         = "me-south-1"
       - dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
    
    2. Migrate local state to remote:
       
       terraform init -migrate-state
       
       When prompted "Do you want to copy existing state to the new backend?"
       Answer: yes
    
    3. Verify migration:
       
       aws s3 ls s3://${aws_s3_bucket.terraform_state.id}/
       terraform state list
    
    4. Deploy main infrastructure:
       
       terraform plan
       terraform apply
    
    EOT
}
