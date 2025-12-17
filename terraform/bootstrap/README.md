# Terraform Bootstrap

This directory contains Terraform code to automatically set up the remote state infrastructure.

## Why Bootstrap?

Instead of manually running AWS CLI commands, Terraform automatically creates:
- S3 bucket for state storage (with versioning, encryption, logging)
- DynamoDB table for state locking
- All necessary security configurations

## Quick Start

### Step 1: Run Bootstrap

```bash
cd terraform/bootstrap

# Initialize Terraform (uses local state, which is fine for bootstrap)
terraform init

# Plan and apply
terraform plan
terraform apply
```

### Step 2: Configure Main Terraform

After bootstrap completes, you'll see outputs like:
```
state_bucket_name = "vndg-terraform-state-123456789012"
dynamodb_table_name = "terraform-locks"
```

Edit `../main.tf` and update the backend configuration:

```hcl
backend "s3" {
  bucket         = "vndg-terraform-state-123456789012"  # From bootstrap output
  key            = "production/terraform.tfstate"
  region         = "me-south-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```

### Step 3: Migrate to Remote State

```bash
cd ..

# Initialize and migrate local state to S3
terraform init -migrate-state

# When prompted "Do you want to copy existing state to the new backend?"
# Answer: yes
```

### Step 4: Deploy Main Infrastructure

```bash
# Verify state is in S3
terraform state list

# Deploy infrastructure
terraform plan -out=tfplan
terraform apply tfplan
```

## What Bootstrap Creates

### S3 Bucket
- ✅ Versioning enabled (state rollback)
- ✅ Encryption enabled (AES256)
- ✅ Public access blocked
- ✅ Access logging enabled (audit trail)
- ✅ Bucket name: `vndg-terraform-state-{ACCOUNT_ID}`

### DynamoDB Table
- ✅ State locking (prevents concurrent modifications)
- ✅ On-demand billing (no provisioned capacity)
- ✅ Table name: `terraform-locks`

### Logging Bucket
- ✅ Access logs for state bucket
- ✅ Useful for auditing state changes

## Files

- `main.tf` - S3 bucket, DynamoDB table, logging configuration
- `variables.tf` - Configurable parameters
- `outputs.tf` - Bucket name, table name, and next steps

## Customization

Edit `variables.tf` to customize:

```hcl
variable "state_bucket_prefix" {
  default = "vndg-terraform-state"  # Change bucket name prefix
}

variable "dynamodb_table_name" {
  default = "terraform-locks"  # Change table name
}
```

## Cleanup (if needed)

To remove bootstrap infrastructure:

```bash
cd terraform/bootstrap
terraform destroy
```

⚠️ WARNING: This will delete the S3 bucket and DynamoDB table, including all state versions!

Only do this if you're completely removing the infrastructure.

## Security

Bootstrap automatically configures:
- ✅ Encryption at rest (S3)
- ✅ Encryption in transit (HTTPS only)
- ✅ Access control (private bucket)
- ✅ Versioning (state recovery)
- ✅ Audit logging
- ✅ State locking (prevent conflicts)

## Troubleshooting

### S3 bucket already exists

If bucket already exists:
```bash
# Import existing bucket
terraform import aws_s3_bucket.terraform_state vndg-terraform-state-123456789012

# Then apply
terraform apply
```

### DynamoDB table already exists

If table already exists:
```bash
# Import existing table
terraform import aws_dynamodb_table.terraform_locks terraform-locks

# Then apply
terraform apply
```

### State migration failed

If migration hangs:
```bash
# Stop the command (Ctrl+C)
# Check local state
terraform state list

# Try again
terraform init -migrate-state
```

## References

- [Terraform S3 Backend](https://www.terraform.io/language/settings/backends/s3)
- [Terraform State Locking](https://www.terraform.io/language/state/locking)
- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
