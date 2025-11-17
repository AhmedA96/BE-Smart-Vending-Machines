# Vending System - Terraform Infrastructure as Code

This directory contains the Terraform configuration for deploying the Vending System architecture on AWS.

## Architecture Overview

Based on the system design document, this Terraform implementation creates:

- **VPC**: Virtual Private Cloud with public and private subnets across multiple AZs
- **Load Balancer**: Application Load Balancer (ALB) for distributing traffic
- **Auto Scaling Groups**:
  - Application servers (handles API requests)
  - Worker nodes (handles background jobs from Redis)
- **Databases**:
  - PostgreSQL RDS with primary-replica setup
  - Redis ElastiCache for caching and job queue
- **Storage**: S3 bucket for external resources (equivalent to R2)
- **DNS**: Cloudflare for domain management
- **Security**: Security groups controlling inter-component communication

## Prerequisites

1. **Terraform**: Version 1.0 or higher
2. **AWS Account**: With appropriate permissions to create VPC, RDS, ElastiCache, EC2, ALB, and S3 resources
3. **AWS CLI**: Configured with credentials
4. **Cloudflare Account**: Domain and DNS management through Cloudflare
5. **Variables**: Create a `terraform.tfvars` file with required variables

## Project Structure

```
terraform/
├── main.tf                 # Provider configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── vpc.tf                  # VPC and networking
├── security_groups.tf      # Security group definitions
├── database.tf             # RDS PostgreSQL database
├── redis.tf                # ElastiCache Redis cluster
├── load_balancer.tf        # ALB configuration
├── autoscaling_app.tf      # Application Auto Scaling Group
├── autoscaling_worker.tf   # Worker Auto Scaling Group
├── storage.tf              # S3 bucket for external storage
├── terraform.tfvars        # Variable values (NOT in version control)
└── README.md               # This file
```

## Getting Started

### Step 1: Initialize Terraform

```bash
cd terraform
terraform init
```

### Step 2: Create terraform.tfvars

Create a `terraform.tfvars` file with your specific values:

```hcl
aws_region      = "us-east-1"
project_name    = "vending-system"
environment     = "production"
db_username     = "admin"
db_password     = "your-secure-password"
domain_name     = "api.vending.example.com"
```

### Step 3: Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the planned changes carefully.

### Step 4: Apply Configuration

```bash
terraform apply tfplan
```

## Deployment Steps

This implementation is designed to be deployed step-by-step for learning and validation:

### Phase 1: Networking Foundation

1. VPC and subnets
2. Internet Gateway and NAT Gateway
3. Route tables

### Phase 2: Security

4. Security groups for all components

### Phase 3: Data Layer

5. RDS PostgreSQL primary and replica
6. Redis ElastiCache cluster

### Phase 4: Network Services

7. Application Load Balancer

### Phase 5: Compute Layer

8. Auto Scaling Group for application servers
9. Auto Scaling Group for worker nodes

### Phase 6: External Services

10. S3 bucket for external storage

## Key Concepts

### Variables

- **Input Variables**: Defined in `variables.tf`, used to customize deployments
- **Sensitive Variables**: `db_password`, `db_username` marked as sensitive
- **Validation**: Environment variable validated against allowed values

### Outputs

- Display important resource identifiers
- Sensitive outputs marked for security
- Used for referencing between modules or external systems

### Resources

- All resources tagged with project, environment, and managed-by metadata
- Regional resources distributed across multiple availability zones for HA
- Security groups implement least-privilege access

### State Management

- Terraform state stored locally by default
- For production, use S3 backend with DynamoDB locks (see commented section in main.tf)

## Validation & Learning Points

### Each Step Focuses On:

1. **Understanding**: What resource does and why it's needed
2. **Configuration**: How to configure it with Terraform
3. **Dependencies**: How it connects to other resources
4. **Security**: Appropriate security configurations

### Best Practices Demonstrated:

- ✅ Modular organization (separate files per component)
- ✅ Reusable variables for customization
- ✅ Descriptive variable names and validation
- ✅ Comprehensive outputs for reference
- ✅ Security groups with minimal required permissions
- ✅ Multi-AZ deployment for high availability
- ✅ Tagging strategy for resource management
- ✅ Sensitive data protection

## Terraform Commands Reference

```bash
# Initialize working directory
terraform init

# Validate configuration
terraform validate

# Format code to standard style
terraform fmt -recursive

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# Output specific value
terraform output vpc_id

# Destroy all resources (use with caution!)
terraform destroy
```

## Troubleshooting

### State Lock

If you encounter a lock error:

```bash
terraform force-unlock <LOCK_ID>
```

### Validate Configuration

```bash
terraform validate
```

### Format Code

```bash
terraform fmt -recursive
```

## Next Steps

After successful deployment:

1. **Configure Secrets in AWS Secrets Manager**:

   - Review: `SECRETS_MANAGER_SETUP.md` for detailed instructions
   - Update secrets with production values:
     - Database credentials
     - Redis connection info
     - Application API keys and secrets
   - Test access from EC2 instances

2. **Configure DNS in Cloudflare**:

   - Get the ALB DNS name from the Terraform output: `terraform output load_balancer_dns`
   - In Cloudflare, create a CNAME record pointing your domain to the ALB
   - Example: `api.vending.example.com` → `<alb-dns-name>`

3. Configure application deployment (via CodeDeploy or similar)
4. Set up monitoring and logging (CloudWatch)
5. Configure backup and disaster recovery policies
6. Enable VPC Flow Logs for network monitoring
7. Set up CI/CD pipeline for infrastructure updates

## Security Considerations

- **Secrets Management**: Use AWS Secrets Manager for all credentials (DB, Redis, API keys)

  - Never commit secrets to Git or environment files
  - Rotate credentials quarterly
  - Monitor secret access via CloudTrail
  - See `SECRETS_MANAGER_SETUP.md` for implementation details

- Store `terraform.tfvars` securely (add to .gitignore)
- Use IAM roles for EC2 instances instead of hardcoded credentials
- Enable RDS encryption at rest (already enabled in `database.tf`)
- Enable S3 bucket versioning and MFA delete
- Regularly rotate database passwords and API keys
- Monitor AWS CloudTrail for infrastructure changes
- Use Terraform Cloud/Enterprise for state locking in team environments
- Keep Terraform state files encrypted (use S3 backend with encryption)

## Support & Learning Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Language Documentation](https://www.terraform.io/language)
- `SECRETS_MANAGER_SETUP.md` - Complete guide to managing credentials with AWS Secrets Manager
- `STEP2_VPC_GUIDE.md` - Deep dive into VPC architecture and networking
- `STEP3_AURORA_GUIDE.md` - Aurora PostgreSQL database configuration details

## Version History

- v1.0 - Initial implementation with core components
