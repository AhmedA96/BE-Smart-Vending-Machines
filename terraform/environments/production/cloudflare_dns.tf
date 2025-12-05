################################################################################
# Cloudflare DNS Configuration
#
# Links the AWS ALB with Cloudflare DNS for domain management
# Automatically creates DNS records pointing to the load balancer
#
# Setup Steps:
# 1. Set Cloudflare API token via TF_VAR_cloudflare_api_token
# 2. Set Cloudflare zone ID via TF_VAR_cloudflare_zone_id  
# 3. Run: terraform plan
# 4. Run: terraform apply
#
# After DNS propagation (5-15 minutes), verify with:
#   dig api.example.com
#   curl -v https://api.example.com/up
################################################################################

# ==============================================================================
# Cloudflare Provider Configuration
# ==============================================================================
# Add to terraform required_providers in main.tf:
#   cloudflare = {
#     source  = "cloudflare/cloudflare"
#     version = "~> 4.0"
#   }

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# ==============================================================================
# Cloudflare DNS Record: Main Domain
# ==============================================================================
# Creates a CNAME record pointing domain to ALB DNS name
# Example: api.vending.example.com → vnd-abcd1234.me-central-1.elb.amazonaws.com

resource "cloudflare_record" "app_domain" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  
  name    = local.subdomain
  type    = "CNAME"
  content = aws_lb.main.dns_name
  ttl     = var.cloudflare_proxy_enabled ? 1 : 3600 # TTL must be 1 when proxied
  proxied = var.cloudflare_proxy_enabled # true = Orange cloud, false = DNS only
  
  comment = "ALB for VNDG ME production environment"
}

# ==============================================================================
# Local Variables for DNS Records
# ==============================================================================
# Extract subdomain from full domain name
# Example: "api.vending.example.com" → subdomain = "api"

locals {
  domain_parts = split(".", var.domain_name)
  # If domain is api.example.com (3 parts), subdomain is "api"
  # If domain is example.com (2 parts), subdomain is "@" (root)
  subdomain = length(local.domain_parts) > 2 ? local.domain_parts[0] : "@"
  root_domain = length(local.domain_parts) > 2 ? join(".", slice(local.domain_parts, 1, length(local.domain_parts))) : var.domain_name
}

# ==============================================================================
# SSL/TLS Certificate via Cloudflare
# ==============================================================================
# Option 1: Use Cloudflare's Universal SSL (Free)
# - Automatically issued for your domain
# - Cloudflare edge → origin (ALB) uses flexible SSL (HTTP)
# - Requires ALB to accept traffic on port 80 (already configured)
#
# Option 2: Use AWS ACM + Cloudflare DNS validation (Recommended)
# - Full end-to-end encryption
# - Cloudflare validates ACM certificate via DNS CNAME
# - See: aws_acm_certificate_validation in load_balancer.tf
#
# This configuration uses Option 2 (ACM + Cloudflare validation)

# ==============================================================================
# ACM Certificate Validation via Cloudflare DNS
# ==============================================================================
# Create DNS records required for ACM certificate validation
# ACM will validate domain ownership by checking these DNS records

resource "cloudflare_record" "acm_validation" {
  for_each = var.cloudflare_zone_id != "" ? {
    for dvo in aws_acm_certificate.main.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}
  
  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.record
  ttl     = 120
  proxied = false # Never proxy validation records!
  
  comment = "ACM certificate validation for ${each.key}"
}

# ==============================================================================
# Uncomment below AFTER applying ACM validation records
# ==============================================================================
# Wait for Cloudflare DNS records to propagate (~5-15 minutes), then uncomment

resource "aws_acm_certificate_validation" "main" {
  count           = var.enable_acm_validation ? 1 : 0
  certificate_arn = aws_acm_certificate.main.arn

  timeouts {
    create = "45m"
  }

  # Ensure DNS records are created before validation
  depends_on = [cloudflare_record.acm_validation]
}

# ==============================================================================
# Cloudflare Page Rules (Optional)
# ==============================================================================
# Example: Redirect HTTP to HTTPS
# Note: Page Rules are deprecated. Use Transform Rules instead.

# Recommended: Configure in Cloudflare dashboard or use Rules API

# ==============================================================================
# DNS Record Outputs
# ==============================================================================
# Use these to verify DNS configuration

output "dns_record_name" {
  description = "Cloudflare DNS record name"
  value       = try(cloudflare_record.app_domain[0].name, null)
}

output "dns_record_target" {
  description = "Cloudflare DNS record target (ALB DNS)"
  value       = try(cloudflare_record.app_domain[0].content, null)
}

output "acm_certificate_arn" {
  description = "ACM Certificate ARN"
  value       = aws_acm_certificate.main.arn
}

output "acm_certificate_domain" {
  description = "ACM Certificate Domain"
  value       = aws_acm_certificate.main.domain_name
}

output "acm_certificate_validation_status" {
  description = "ACM Certificate Validation Status"
  value       = try(aws_acm_certificate_validation.main[0].certificate_arn, "Pending - Enable validation and apply")
}

# ==============================================================================
# Cloudflare DNS Setup Instructions
# ==============================================================================
#
# STEP 1: Enable Cloudflare for your domain
# =========================================
# 1. Log in to Cloudflare dashboard
# 2. Add site: your-domain.com
# 3. Update nameservers at your domain registrar:
#    - ns1.cloudflare.com
#    - ns2.cloudflare.com
# 4. Wait for nameserver propagation (up to 48 hours)
# 5. Verify: dig ns your-domain.com
#
# STEP 2: Get API Token
# ====================
# 1. Go to Cloudflare dashboard → Account Settings → API Tokens
# 2. Create Token with permissions:
#    - Zone.DNS:Edit
#    - Zone.Zone:Read
# 3. Restrict to your zone (e.g., example.com)
# 4. Copy token and set environment variable:
#    export TF_VAR_cloudflare_api_token="your-token-here"
#
# STEP 3: Get Zone ID
# ==================
# 1. Go to Cloudflare dashboard → Select domain
# 2. On Overview tab, scroll to "API" section
# 3. Copy Zone ID (e.g., d1a2b3c4e5f6g7h8i9j0k1l2m3n4o5p6)
# 4. Set environment variable:
#    export TF_VAR_cloudflare_zone_id="your-zone-id-here"
#
# STEP 4: Deploy
# ==============
# 1. Ensure domain_name, cloudflare_api_token, and cloudflare_zone_id are set
# 2. Run: terraform plan -out=tfplan
# 3. Verify DNS records in output
# 4. Run: terraform apply tfplan
# 5. Wait 5-15 minutes for DNS propagation
#
# STEP 5: Enable ACM Validation
# =============================
# After DNS propagates:
# 1. Verify DNS records exist:
#    dig _abcd1234.api.example.com @ns1.cloudflare.com
# 2. Set: enable_acm_validation = true in terraform.tfvars
# 3. Run: terraform apply
# 4. Wait for ACM validation to complete (5-15 minutes)
#
# STEP 6: Verify
# ==============
# 1. Check DNS resolution:
#    dig api.example.com
#    → Should return ALB IP address
#
# 2. Check certificate:
#    curl -v https://api.example.com/up
#    → Should return 200 OK with valid certificate
#
# 3. Check Cloudflare DNS:
#    In Cloudflare dashboard → DNS tab
#    → Should show CNAME record for api.example.com → ALB DNS
#
# STEP 7: Configure SSL/TLS in Cloudflare (Optional)
# ==================================================
# In Cloudflare dashboard:
# 1. SSL/TLS → Overview: Set to "Full (strict)"
#    - Requires valid certificate on ALB (ACM handles this)
# 2. SSL/TLS → Edge Certificates: Enable "Always Use HTTPS"
# 3. SSL/TLS → Minimum TLS Version: Set to "1.2" or "1.3"
#
# ==============================================================================
