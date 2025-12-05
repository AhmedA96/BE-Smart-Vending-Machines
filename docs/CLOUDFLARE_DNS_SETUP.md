# Cloudflare DNS Integration Setup Guide

## Overview

This guide walks you through linking your AWS Application Load Balancer (ALB) with Cloudflare DNS and setting up SSL/TLS certificates.

**Architecture:**

```
Domain (api.example.com)
    ↓
Cloudflare DNS (CNAME record)
    ↓
AWS ALB (public IP)
    ↓
App Servers (private subnet)
```

---

## Prerequisites

- [x] Cloudflare account with your domain
- [x] Domain nameservers already pointing to Cloudflare
- [x] AWS ALB deployed (via Terraform)
- [x] Terraform installed with AWS credentials configured

---

## Step-by-Step Setup

### Step 1: Get Cloudflare API Token

**Location:** Cloudflare Dashboard → Account Settings → API Tokens

1. Click **"Create Token"**
2. Use template: **"Edit zone DNS"** OR create custom token with:
   - **Permissions:**
     - `Zone.DNS` → **Edit**
     - `Zone.Zone` → **Read**
   - **Zone Resources:** Select your domain (e.g., `example.com`)
3. **TTL:** Set to 12 months or longer
4. Click **"Create Token"** and copy the token immediately

**Example token:** `v1.0-abc123def456...`

---

### Step 2: Get Cloudflare Zone ID

**Location:** Cloudflare Dashboard → Your Domain → Overview

1. Scroll to **"API"** section (right sidebar)
2. Find **"Zone ID"** (32-character hex string)
3. Copy the Zone ID

**Example Zone ID:** `d1a2b3c4e5f6g7h8i9j0k1l2m3n4o5p6`

---

### Step 3: Update Terraform Variables

Edit `terraform/environments/production/terraform.tfvars`:

```hcl
# Existing variables...
domain_name = "api.example.com"

# NEW: Cloudflare Configuration
cloudflare_api_token = "v1.0-your-token-here"
cloudflare_zone_id   = "d1a2b3c4e5f6g7h8i9j0k1l2m3n4o5p6"

# Start with false, enable after DNS records are created
enable_acm_validation = false
```

**Or** use environment variables instead of tfvars:

```bash
export TF_VAR_cloudflare_api_token="v1.0-your-token-here"
export TF_VAR_cloudflare_zone_id="d1a2b3c4e5f6g7h8i9j0k1l2m3n4o5p6"
```

---

### Step 4: Create DNS Records (Part 1)

Run Terraform with ACM validation disabled:

```bash
cd terraform/environments/production

# Initialize (first time only)
terraform init

# Plan the changes
terraform plan -out=tfplan

# Review the output - you should see:
# - cloudflare_record.app_domain (CNAME to ALB)
# - cloudflare_record.acm_validation (DNS validation records)
# - aws_acm_certificate (SSL certificate)

# Apply
terraform apply tfplan
```

**What was created:**

- ✅ Cloudflare CNAME record: `api.example.com` → ALB DNS name
- ✅ Cloudflare validation records for ACM certificate
- ✅ AWS ACM certificate (awaiting validation)

**Check the outputs:**

```bash
terraform output dns_record_name
terraform output dns_record_target
terraform output acm_certificate_arn
```

---

### Step 5: Wait for DNS Propagation

**Timeframe:** 5-15 minutes (typically 5 minutes)

**Verify DNS is working:**

```bash
# Method 1: dig (recommended)
dig api.example.com

# Expected output:
# api.example.com.     3600    IN    CNAME    vnd-abcd1234.me-central-1.elb.amazonaws.com.
# vnd-abcd1234...      300     IN    A        203.0.113.45

# Method 2: nslookup
nslookup api.example.com

# Method 3: curl (will fail with cert error, that's OK)
curl -v https://api.example.com/up 2>&1 | grep -i "SSL\|certificate"
```

**DNS is ready when:**

- `dig api.example.com` returns the ALB IP address
- Cloudflare shows the DNS record as "Active" (orange cloud icon)

---

### Step 6: Enable ACM Certificate Validation

Once DNS is propagated and ACM validation records are in place:

1. **Update terraform.tfvars:**

```hcl
enable_acm_validation = true  # Changed from false
```

2. **Apply the changes:**

```bash
terraform apply
```

**What happens:**

- Terraform waits for ACM to validate the certificate
- Takes 5-15 minutes (AWS validates via DNS records)
- Once valid, ALB automatically uses the certificate

**Monitor validation status:**

```bash
# Check ACM certificate status
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:me-central-1:YOUR_ACCOUNT_ID:certificate/YOUR_CERT_ID \
  --region me-central-1 \
  --query 'Certificate.Status' \
  --output text

# Expected output after validation: ISSUED
```

---

### Step 7: Verify Everything Works

**Test 1: DNS Resolution**

```bash
dig api.example.com

# Should resolve to ALB IP
```

**Test 2: HTTP Redirect**

```bash
curl -v http://api.example.com/up 2>&1 | grep -E "301|302|Location"

# Expected: 301 redirect to https://
```

**Test 3: HTTPS with Certificate**

```bash
curl -v https://api.example.com/up

# Expected:
# - HTTP 200 OK
# - Valid SSL certificate
# - "SSL connection using TLS..." in verbose output
```

**Test 4: Health Check**

```bash
curl https://api.example.com/up
# Expected: {"status":"ok"} or similar
```

**Test 5: Application Endpoint**

```bash
curl https://api.example.com/api/v1/health
# Expected: Response from your Rails app
```

---

## Cloudflare SSL/TLS Configuration (Optional)

For full end-to-end encryption, configure in Cloudflare dashboard:

### Cloudflare Dashboard → SSL/TLS → Overview

Set to: **"Full (strict)"**

- Requires valid certificate on origin (ALB) ✅ We have this

### Cloudflare Dashboard → SSL/TLS → Edge Certificates

- **Enable:** "Always Use HTTPS" ✅ Recommended
- **Minimum TLS Version:** "1.2" or "1.3" ✅ Recommended
- **Automatic HTTPS Rewrites:** Enable ✅ Optional

### Cloudflare Dashboard → SSL/TLS → Origin Server

Optional: Upload your own certificate or let AWS/Cloudflare handle it

---

## Traffic Flow Verification

After setup is complete, traffic should flow like this:

```
1. User visits: https://api.example.com/api/v1/...
                        ↓
2. Browser resolves DNS (Cloudflare)
                        ↓
3. Browser connects to ALB (TLS 1.2/1.3)
                        ↓
4. ALB terminates SSL/TLS (AWS ACM certificate)
                        ↓
5. ALB routes to healthy app server (port 80)
                        ↓
6. App server handles request
                        ↓
7. Response flows back through ALB → Cloudflare → User
```

---

## Troubleshooting

### Problem: DNS resolves but certificate validation fails

**Cause:** Cloudflare validation records haven't propagated

**Solution:**

```bash
# Check if validation records exist
dig _abcd1234.api.example.com @ns1.cloudflare.com

# If not showing, wait another 5 minutes and retry
# If still missing, verify records in Cloudflare dashboard

# You can also check Terraform output
terraform output certificate_domain_validation_options
```

### Problem: ACM certificate stuck in "Pending Validation"

**Cause:** Cloudflare DNS records not created or TTL too long

**Solution:**

1. Check Cloudflare dashboard DNS tab
2. Ensure validation records exist (ones with `_` prefix)
3. If missing, re-run: `terraform apply`
4. If present, wait 15-30 minutes for AWS to validate

### Problem: Certificate validation timeout (45 minutes)

**Cause:** DNS records permanently missing or incorrect

**Solution:**

```bash
# 1. Check what records Terraform is trying to create
terraform output certificate_domain_validation_options

# 2. Manually verify in Cloudflare dashboard
# 3. Check that cloudflare_api_token has correct permissions
# 4. Destroy and recreate certificate:
terraform destroy -auto-approve
terraform apply

# Then enable validation:
# Set: enable_acm_validation = true
terraform apply
```

### Problem: curl shows "SSL certificate problem: self signed certificate"

**Cause:** Certificate not yet issued OR Cloudflare SSL setting wrong

**Solution:**

```bash
# Check ACM status
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw acm_certificate_arn) \
  --region me-central-1

# Status should be "ISSUED", not "PENDING_VALIDATION"

# Also check Cloudflare SSL/TLS settings:
# Should be "Full (strict)" not "Flexible"
```

### Problem: "Certificate validation failed with error"

**Cause:** Domain name mismatch or zone ID incorrect

**Solution:**

```bash
# Verify domain_name matches Cloudflare zone
echo "Domain in Terraform: $(terraform output -raw domain_name)"
echo "Cloudflare Zone: $(terraform output -raw cloudflare_zone_id)"

# They should match (minus subdomains)
# Example:
#   domain: api.example.com
#   zone: example.com zone ID
```

---

## Rollback

If something goes wrong, you can remove Cloudflare integration:

```bash
# Option 1: Disable without destroying
# Edit terraform.tfvars:
#   cloudflare_zone_id = ""

terraform apply  # Removes Cloudflare resources

# Option 2: Destroy Cloudflare resources
terraform destroy -target=cloudflare_record.app_domain -target=cloudflare_record.acm_validation
```

---

## Next Steps

After successful setup:

1. **Monitor Certificate Expiry**

   - ACM auto-renews certificates 30 days before expiry
   - No action needed from you

2. **Configure Cloudflare Rules (Optional)**

   - Set up page rules for redirects
   - Configure rate limiting
   - Set up Web Application Firewall (WAF)

3. **Monitor in CloudWatch**

   - Watch ALB logs for errors
   - Monitor app server health checks

4. **Update Documentation**
   - Document your domain/ALB configuration
   - Add to runbooks

---

## References

- [Cloudflare API Token Docs](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)
- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [AWS ACM with Cloudflare DNS](https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html)
- [Cloudflare SSL/TLS Settings](https://developers.cloudflare.com/ssl/concepts/ssl-tls-versions/)

---

## Summary of Changes Made

### Files Created:

- `terraform/environments/production/cloudflare_dns.tf` - Cloudflare DNS and ACM validation

### Files Modified:

- `terraform/environments/production/main.tf` - Added Cloudflare provider
- `terraform/environments/production/variables.tf` - Added Cloudflare variables
- `terraform/environments/production/load_balancer.tf` - Updated ACM validation docs

### New Variables:

- `cloudflare_api_token` - Cloudflare API token (sensitive)
- `cloudflare_zone_id` - Cloudflare Zone ID
- `cloudflare_proxy_enabled` - Enable Cloudflare proxy (default: true)
- `enable_acm_validation` - Enable ACM certificate validation (default: false)

---

## Automation Ready

This setup is fully automated with Terraform. After initial Cloudflare configuration:

```bash
# One-command deployment
terraform apply

# Certificate validation happens automatically
# No manual DNS record creation needed
# Certificate auto-renewal handled by AWS
```

---

**Questions? Check the troubleshooting section or review the comments in `cloudflare_dns.tf`**
