# Vending System - Terraform Infrastructure

Production infrastructure for the Vending System on AWS.

## Quick Start

```bash
cd environments/production

# Configure
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Add your secrets

# Deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Directory Structure

```
terraform/
├── environments/
│   └── production/         # Production infrastructure
│       ├── *.tf           # 14 Terraform files
│       ├── backend.tf     # S3 state configuration
│       ├── terraform.tfvars.example
│       ├── README.md      # Deployment guide
│       ├── MULTI_AZ_CHANGES.md
│       └── PRE_DEPLOYMENT_CHECKLIST.md
├── modules/               # Future: Reusable modules
│   ├── vpc/
│   ├── database/
│   └── ...
└── bootstrap/             # One-time backend setup
```

## Architecture

### Infrastructure Components

| Component | Configuration | Cost/mo |
|-----------|--------------|---------|
| **VPC** | 2 AZs, 6 subnets | $0 |
| **NAT Gateway** | 1 (cost optimized) | ~$35 |
| **ALB** | Across 2 AZs | ~$20 |
| **Aurora PostgreSQL** | Primary + replica (t3.small) | ~$120 |
| **Redis** | Primary + replica (t3.micro) | ~$36 |
| **App Servers** | 2-4 instances (t3.micro) | ~$15-30 |
| **Workers** | 2-5 instances (t3.micro) | ~$15-38 |
| **Storage** | S3/R2 buckets | ~$10 |
| **CloudWatch** | Logs + metrics | ~$15 |
| **Total** | | **~$270-320** |

### Network Architecture

```
Internet
   ↓
┌──────────────────────────────────────────┐
│ ALB (2 AZs: me-central-1a, me-central-1b)   │
└──────────────────────────────────────────┘
   ↓
┌──────────────────────────────────────────┐
│ App Servers (AZ-a)                       │
│ • Auto-scaling: 2-4 instances            │
│ • Security: Private subnet               │
└──────────────────────────────────────────┘
   ↓                           ↓
┌─────────────────┐    ┌──────────────┐
│ Aurora DB       │    │ Redis Cache  │
│ • Primary       │    │ • Primary    │
│ • Replica       │    │ • Replica    │
│ (AZ-a)          │    │ (AZ-a)       │
└─────────────────┘    └──────────────┘
```

## Deployment

### Prerequisites

1. **AWS Account** with admin access
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured

### Step 1: Bootstrap (One-time)

```bash
cd bootstrap
terraform init
terraform apply
# Note the S3 bucket name for state
```

### Step 2: Configure Production

```bash
cd environments/production

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Generate secrets
openssl rand -hex 64  # rails_secret_key_base
openssl rand -hex 64  # jwt_secret  
openssl rand -hex 32  # rails_master_key
openssl rand -base64 32  # db_password

# Edit config with your values
vim terraform.tfvars
```

**Required variables:**
- `db_password` - Strong database password
- `rails_master_key` - Rails credentials key
- `rails_secret_key_base` - Session signing key
- `jwt_secret` - API token signing key
- `domain_name` - Your domain (e.g., api.example.com)

### Step 3: Deploy Infrastructure

```bash
cd environments/production

# Initialize Terraform
terraform init

# Review changes
terraform plan -out=tfplan

# Apply (takes ~15-20 minutes)
terraform apply tfplan

# Get outputs
terraform output
```

### Step 4: Post-Deployment

```bash
# Get ALB DNS
terraform output load_balancer_dns

# Configure DNS (Cloudflare)
# Create CNAME: api.yourdomain.com → <alb-dns>

# Subscribe to alerts
terraform output | grep alerts
aws sns subscribe \
  --topic-arn <alerts-topic-arn> \
  --protocol email \
  --notification-endpoint your@email.com
```

## Cost Optimization

Current configuration uses **single-AZ deployment** with cost optimizations:

✅ **What Saves Money:**
- Single NAT Gateway (saves ~$35/mo vs 2 NATs)
- Single-AZ RDS (saves ~$60/mo vs Multi-AZ)
- Single-AZ Redis (saves ~$18/mo vs Multi-AZ)
- All compute in one AZ (saves cross-AZ transfer fees)

⚠️ **Trade-offs:**
- AZ failure causes full outage
- No automatic cross-AZ failover
- Limited by single AZ capacity

💡 **To Upgrade to Full HA:**
```hcl
# In terraform.tfvars:
db_multi_az = true
multi_az_enabled = true  # Redis

# Add 2nd NAT Gateway
# Deploy resources across both AZs
# Cost: +$100-105/month
```

## Management

### Update Infrastructure

```bash
cd environments/production

# Edit any .tf file
vim vpc.tf

# Review changes
terraform plan

# Apply
terraform apply
```

### View Current State

```bash
cd environments/production
terraform show
terraform state list
```

### Destroy Infrastructure

```bash
cd environments/production

# WARNING: This deletes everything!
terraform destroy
```

## Security

### Secrets Management

All secrets stored in **AWS Secrets Manager**:
- Database credentials
- Redis connection info
- Application secrets (Rails, JWT)
- Third-party API keys

**Never commit to git:**
- `terraform.tfvars`
- `*.tfstate`
- `.terraform/`

### Network Security

- ✅ Private subnets for all compute
- ✅ Security groups with least privilege
- ✅ Encrypted storage (RDS, Redis, EBS)
- ✅ KMS encryption for secrets
- ✅ ALB as single entry point

### Recommended Actions

- [ ] Enable MFA on AWS root account
- [ ] Set up CloudTrail logging
- [ ] Configure VPC Flow Logs
- [ ] Enable AWS GuardDuty
- [ ] Add WAF to ALB (production)
- [ ] Rotate secrets quarterly

## Monitoring

### CloudWatch Alarms

Alerts configured for:
- High CPU (app, database, Redis)
- Unhealthy targets (ALB)
- Database connections
- Redis memory/evictions
- HTTP 5xx errors

### Dashboard

```bash
# View dashboard
AWS Console → CloudWatch → Dashboards → vending-system-production
```

### Logs

```bash
# View logs
AWS Console → CloudWatch → Log Groups
- /aws/ec2/vending-system/*
- /aws/rds/cluster/vending-system-aurora-cluster
- /aws/elasticache/vending-system/redis-*
```

## Troubleshooting

### Common Issues

**Issue:** Terraform state lock
```bash
terraform force-unlock <LOCK_ID>
```

**Issue:** Plan shows unexpected changes
```bash
terraform refresh
terraform plan
```

**Issue:** Resources fail to create
```bash
# Check AWS service quotas
# Verify IAM permissions
# Review CloudWatch events
```

### Getting Help

1. Check `environments/production/README.md` for deployment details
2. Review `environments/production/PRE_DEPLOYMENT_CHECKLIST.md`
3. See `environments/production/MULTI_AZ_CHANGES.md` for recent updates

## Adding Environments

To create staging or dev:

```bash
# Copy production
cp -r environments/production environments/staging
cd environments/staging

# Customize (smaller instances)
vim variables.tf
vim terraform.tfvars

# Update backend key
vim backend.tf  # Change key to "staging/terraform.tfstate"

# Deploy
terraform init
terraform plan
terraform apply
```

## Modules (Future)

Extract reusable components:

```bash
# Example: VPC module
mkdir -p modules/vpc
# Move VPC resources
# Reference from environments
```

## Backup & Recovery

### State Backups

- State stored in S3 with versioning
- DynamoDB for state locking
- Encrypted at rest

### Database Backups

- Automated backups: 7 days retention
- Manual snapshots available
- Point-in-time recovery enabled

### Disaster Recovery

1. Infrastructure: Re-run terraform apply
2. Database: Restore from RDS snapshot
3. Application: Redeploy from git

## Support

- **AWS Documentation:** https://docs.aws.amazon.com
- **Terraform:** https://www.terraform.io/docs
- **Production Issues:** Check CloudWatch alarms and logs

---

**Version:** 1.0  
**Last Updated:** 2025-11-18  
**Status:** ✅ Production Ready
