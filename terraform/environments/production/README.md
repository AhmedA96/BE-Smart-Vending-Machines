# Production Environment

Production infrastructure configuration for the Vending System.

## Quick Deploy

```bash
# 1. Configure
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# 2. Initialize
terraform init

# 3. Deploy
terraform plan -out=tfplan
terraform apply tfplan
```

## Configuration

See `terraform.tfvars.example` for all available variables.

**Required secrets:**
- `db_password`
- `rails_master_key`
- `rails_secret_key_base`
- `jwt_secret`
- `domain_name`

## Infrastructure

- **VPC:** 2 AZs (me-central-1a, me-central-1b)
- **Compute:** Auto-scaling app (2-4) + workers (2-5)
- **Database:** Aurora PostgreSQL (primary + replica)
- **Cache:** Redis (primary + replica)
- **Load Balancer:** ALB across 2 AZs
- **Cost:** ~$270-320/month

## State Backend

After running `terraform/bootstrap`, update `backend.tf` with your account ID:

```hcl
bucket = "vndg-terraform-state-YOUR_ACCOUNT_ID"
```

Then migrate state:
```bash
terraform init -migrate-state
```

## Documentation

- `MULTI_AZ_CHANGES.md` - Recent infrastructure updates
- `PRE_DEPLOYMENT_CHECKLIST.md` - Detailed deployment steps
- `../../README.md` - Main documentation

## Common Commands

```bash
# View outputs
terraform output

# Update infrastructure  
terraform plan
terraform apply

# View state
terraform show
terraform state list

# Destroy (careful!)
terraform destroy
```

---

For complete documentation, see the main [README](../../README.md).
