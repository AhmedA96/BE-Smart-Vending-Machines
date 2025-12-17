# Backend configuration for production environment
# Uncomment after running bootstrap

# terraform {
#   backend "s3" {
#     bucket         = "vndg-terraform-state-YOUR_ACCOUNT_ID"
#     key            = "production/terraform.tfstate"
#     region         = "me-south-1"
#     encrypt        = true
#     dynamodb_table = "terraform-locks"
#   }
# }
