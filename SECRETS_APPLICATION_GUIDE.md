# Application Secrets Integration Guide

Complete guide to using AWS Secrets Manager in your Rails application.

---

## Overview

Your Rails application is configured to automatically load secrets from AWS Secrets Manager on startup. This guide explains how to:

1. Set up secrets locally for development
2. Access secrets in your code
3. Rotate secrets safely
4. Handle secret loading errors

---

## File Structure

```
app/
  services/
    secrets_manager_service.rb      # Service for fetching secrets from AWS

config/
  initializers/
    secrets_manager.rb              # Auto-loads secrets on Rails startup
  database.yml                      # Updated to use loaded secrets
  environments/
    production.rb
    staging.rb
    development.rb

.env.example                        # Template for local environment variables
```

---

## Local Development Setup

### Step 1: Copy .env.example to .env

```bash
cp .env.example .env
```

### Step 2: Configure .env for Local Development

```bash
# .env (local development)

# Disable AWS Secrets Manager (use .env file instead)
AWS_LOAD_SECRETS=false

# Database (local PostgreSQL)
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_NAME=vndgme_development

# Redis (local)
REDIS_HOST=localhost
REDIS_PORT=6379

# Rails secrets (generate these)
RAILS_MASTER_KEY=<generate with: rails secret>
SECRET_KEY_BASE=<generate with: rails secret>
JWT_SECRET=<generate with: rails secret>
```

### Step 3: Generate Rails Secrets

```bash
# Generate a new Rails master key
rails secret

# Generate SECRET_KEY_BASE
rails secret

# Generate JWT_SECRET
rails secret

# Add these to .env file
```

### Step 4: Verify Setup

```bash
# Start Rails console
rails console

# Check if ENV variables are loaded
ENV['DATABASE_HOST']
# => "localhost"

ENV['REDIS_HOST']
# => "localhost"

# Check if service is available
SecretsManagerService.cache_stats
# => {:cached_secrets=>0, :cache_keys=>[]}
```

---

## Production/Staging Setup

### Step 1: Deploy Terraform

```bash
cd terraform/
terraform plan -out=tfplan
terraform apply tfplan
```

This creates:

- KMS key for encryption
- 3 secrets in AWS Secrets Manager
- IAM role for EC2 instances

### Step 2: Verify Secrets Created

```bash
# List all secrets
aws secretsmanager list-secrets --region me-south-1

# Get database credentials
aws secretsmanager get-secret-value \
  --secret-id vending-system/production/db/credentials \
  --region me-south-1 \
  --query SecretString \
  --output text | jq '.'
```

### Step 3: Configure EC2 Launch

When launching EC2 instances, set:

```bash
export AWS_LOAD_SECRETS=true
export AWS_REGION=me-south-1
export SECRETS_PROJECT=vending-system
```

The `config/initializers/secrets_manager.rb` will automatically:

1. Load database credentials
2. Load Redis credentials
3. Load application secrets
4. Populate ENV variables

### Step 4: Verify on Running Instance

SSH into EC2 instance:

```bash
# Check if secrets loaded
echo $DATABASE_HOST
# Should show: vending-system-cluster.c9akciq32.us-east-1.rds.amazonaws.com

# Check Rails logs
tail -f log/production.log | grep "secrets loaded"
```

---

## Accessing Secrets in Code

### Approach 1: ENV Variables (Recommended)

All secrets are automatically loaded into ENV variables by the initializer:

```ruby
# config/initializers/secrets_manager.rb auto-loads:
ENV['DATABASE_HOST']
ENV['DATABASE_PASSWORD']
ENV['REDIS_HOST']
ENV['JWT_SECRET']
ENV['SUPPLIER_API_KEY']
```

Use them directly in code:

```ruby
# In models/services
class SupplierSyncService
  def initialize
    @api_key = ENV['SUPPLIER_API_KEY']
    @api_secret = ENV['SUPPLIER_API_SECRET']
  end
end

# In controllers
class ApiController < ApplicationController
  before_action :verify_jwt_token

  def verify_jwt_token
    token = request.headers['Authorization']&.split(' ')&.last
    JWT.decode(token, ENV['JWT_SECRET'])
  end
end

# In initializers
Credential.jwt_secret = ENV['JWT_SECRET']
```

### Approach 2: Direct Service Call

For dynamic or rarely-used secrets:

```ruby
# Fetch secret directly from Secrets Manager
begin
  secret = SecretsManagerService.get_secret(
    'vending-system/production/app/secrets'
  )

  supplier_key = secret['api_keys']['supplier_api_key']
rescue SecretsManagerService::SecretNotFound => e
  Rails.logger.error("Secret not found: #{e.message}")
  # Handle error - use fallback or raise
end
```

### Approach 3: Rails Credentials (Alternative)

For additional application-specific secrets not in Secrets Manager:

```bash
# Edit encrypted credentials file
rails credentials:edit

# Add secrets to config/credentials.yml.enc
# Example:
# aws:
#   access_key_id: xxx
#   secret_access_key: yyy

# Access in code
Rails.application.credentials.aws.access_key_id
```

---

## Error Handling

### Catching Specific Errors

```ruby
class InitializeSecretsJob
  include Sidekiq::Worker

  def perform
    begin
      SecretsManagerService.get_secret('my-secret')
    rescue SecretsManagerService::SecretNotFound => e
      Rails.logger.error("Secret missing: #{e.message}")
      # Notify ops team
      send_alert("Secret not found: my-secret")
    rescue SecretsManagerService::DecryptionError => e
      Rails.logger.error("KMS decryption failed: #{e.message}")
      # Check KMS key permissions
      send_alert("KMS decryption failed - check key permissions")
    rescue SecretsManagerService::ServiceUnavailable => e
      Rails.logger.error("AWS temporarily unavailable: #{e.message}")
      # Retry after delay
      self.class.perform_in(5.minutes)
    end
  end
end
```

### Handling Missing Secrets Gracefully

```ruby
# In config/initializers/secrets_manager.rb

def load_redis_secrets
  # ... existing code ...
rescue SecretsManagerService::SecretNotFound
  # Redis is optional, only required if using Kredis/Sidekiq
  if ENV['REDIS_URL'].present?
    Rails.logger.warn("Redis secret not found but REDIS_URL is set")
  else
    Rails.logger.warn("Redis not configured - features requiring Redis will be unavailable")
  end
end
```

---

## Using Secrets in Different Scenarios

### Database Connections

```ruby
# Automatically configured by secrets_manager.rb initializer
# In config/database.yml:
host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>
username: <%= ENV.fetch("DATABASE_USER", "postgres") %>
password: <%= ENV.fetch("DATABASE_PASSWORD", "postgres") %>
port: <%= ENV.fetch("DATABASE_PORT", 5432) %>
```

### Redis Connections

```ruby
# Automatically configured by secrets_manager.rb initializer
# In Kredis config:
Kredis.configure do
  redis_url = "redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}"
end
```

### Third-party APIs

```ruby
# app/services/supplier_integration_service.rb

class SupplierIntegrationService
  def initialize
    @api_key = ENV['SUPPLIER_API_KEY']
    @api_secret = ENV['SUPPLIER_API_SECRET']
  end

  def sync_machines
    HTTParty.get(
      'https://api.supplier.com/machines',
      headers: {
        'Authorization' => "Bearer #{@api_key}",
        'X-Secret' => @api_secret
      }
    )
  end
end

# Usage
SupplierIntegrationService.new.sync_machines
```

### JWT Token Signing

```ruby
# app/services/token_service.rb

class TokenService
  def self.create_token(user_id)
    payload = {
      user_id: user_id,
      iat: Time.current.to_i,
      exp: 1.day.from_now.to_i
    }

    JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
  end

  def self.decode_token(token)
    JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' })
  rescue JWT::DecodeError => e
    raise "Invalid token: #{e.message}"
  end
end

# Usage
token = TokenService.create_token(user.id)
payload = TokenService.decode_token(token)
```

### Environment-specific Configuration

```ruby
# app/config/initializers/external_services.rb

case Rails.env
when 'production', 'staging'
  # Use secrets from Secrets Manager
  PAYMENT_CONFIG = {
    api_key: ENV['PAYMENT_PROVIDER_KEY'],
    base_url: 'https://api.payment.com'
  }
when 'development'
  # Use .env file
  PAYMENT_CONFIG = {
    api_key: ENV['PAYMENT_PROVIDER_KEY'] || 'dev-key',
    base_url: 'https://sandbox.payment.com'
  }
end
```

---

## Cache Behavior

The `SecretsManagerService` caches secrets in memory for performance:

```ruby
# Default cache TTL: 1 hour (3600 seconds)
secret = SecretsManagerService.get_secret('my-secret')
# Cached for 1 hour

# Override cache TTL
secret = SecretsManagerService.get_secret('my-secret', cache_ttl: 300)
# Cached for 5 minutes only

# Disable cache
secret = SecretsManagerService.get_secret('my-secret', use_cache: false)
# Always fetch fresh from Secrets Manager

# Clear specific secret from cache
SecretsManagerService.clear_cache('my-secret')

# Clear entire cache
SecretsManagerService.clear_cache

# Check cache stats
stats = SecretsManagerService.cache_stats
# => {:cached_secrets=>2, :cache_keys=>["vending-system/production/db/credentials", "..."]}
```

### Cache Considerations

- **Pros**: Reduced API calls, faster secret access, lower costs
- **Cons**: Cached secrets won't reflect immediate updates

When rotating secrets:

1. Update secret in Secrets Manager
2. Clear application cache: `SecretsManagerService.clear_cache`
3. Restart application or reload secrets

---

## Rotating Secrets

### Scenario 1: Rotate Database Password

```bash
# 1. Generate new password
NEW_PASSWORD=$(openssl rand -base64 32)

# 2. Update Aurora master password
aws rds modify-db-cluster \
  --db-cluster-identifier vending-system \
  --master-user-password "$NEW_PASSWORD" \
  --apply-immediately \
  --region me-south-1

# 3. Update Secrets Manager
aws secretsmanager update-secret \
  --secret-id vending-system/production/db/credentials \
  --secret-string "{\"username\":\"admin\",\"password\":\"$NEW_PASSWORD\",\"host\":\"...\",\"port\":5432,\"dbname\":\"vendingdb\"}" \
  --region me-south-1

# 4. Clear application cache
# SSH to each EC2 instance and run:
rails runner "SecretsManagerService.clear_cache('vending-system/production/db/credentials')"

# 5. Restart applications
systemctl restart vending-system
```

### Scenario 2: Rotate JWT Secret

```bash
# 1. Generate new JWT secret
NEW_JWT_SECRET=$(rails secret)

# 2. Update Secrets Manager
aws secretsmanager update-secret \
  --secret-id vending-system/production/app/secrets \
  --secret-string "{\"rails_master_key\":\"...\",\"jwt_secret\":\"$NEW_JWT_SECRET\",\"...\":\"...\"}" \
  --region me-south-1

# 3. Clear cache
rails runner "SecretsManagerService.clear_cache"

# 4. Restart applications
systemctl restart vending-system

# Note: Existing JWT tokens will still be valid for their TTL
# New tokens created after restart will use new secret
```

---

## Troubleshooting

### Secret Not Found Error

```
SecretsManagerService::SecretNotFound: Secret 'vending-system/production/db/credentials' not found in AWS Secrets Manager
```

**Solutions**:

1. Verify secret exists: `aws secretsmanager list-secrets --region me-south-1`
2. Check secret name matches exactly
3. Verify EC2 instance has IAM role permissions
4. Check CloudTrail for API errors

### KMS Decryption Failed

```
SecretsManagerService::DecryptionError: Failed to decrypt secret using KMS key
```

**Solutions**:

1. Verify KMS key permissions: `aws kms describe-key --key-id alias/vending-system-secrets`
2. Check EC2 IAM role has kms:Decrypt permission
3. Verify KMS key is in correct region

### AWS Service Unavailable

```
SecretsManagerService::ServiceUnavailable: AWS Secrets Manager temporarily unavailable
```

**Solutions**:

1. Check AWS service status
2. Verify network connectivity from EC2 to Secrets Manager
3. Retry after exponential backoff (automatic in SecretsManagerService)

### Testing Secret Loading

```ruby
# In Rails console
rails console

# Check if secrets loaded
ENV['DATABASE_HOST']
# Should show database host

# Test service directly
SecretsManagerService.get_secret('vending-system/production/db/credentials')
# Should return parsed JSON

# Check permissions
aws sts get-caller-identity
# Verify using EC2 instance profile
```

---

## Best Practices Checklist

✅ **DO**:

- [ ] Never commit `.env` to git
- [ ] Use `.env.example` as template only
- [ ] Generate strong secrets (32+ characters)
- [ ] Rotate secrets every 30-90 days
- [ ] Use environment-specific secret names
- [ ] Clear cache after rotation
- [ ] Monitor secret access in CloudTrail
- [ ] Test error handling for missing secrets
- [ ] Use IAM roles, not access keys
- [ ] Enable MFA for Secrets Manager console access

❌ **DON'T**:

- [ ] Store secrets in code or git history
- [ ] Log secret values
- [ ] Share secrets across environments
- [ ] Use weak/default passwords
- [ ] Disable KMS encryption
- [ ] Give all services access to all secrets
- [ ] Commit terraform.tfvars
- [ ] Use plaintext HTTP for secret APIs

---

## Integration Checklist

- [ ] Updated Gemfile with AWS SDK gems
- [ ] Created SecretsManagerService (app/services/secrets_manager_service.rb)
- [ ] Created secrets_manager.rb initializer
- [ ] Updated database.yml to use ENV variables
- [ ] Created .env.example template
- [ ] Deployed Terraform (terraform apply)
- [ ] Verified secrets created in AWS console
- [ ] Set AWS_LOAD_SECRETS=true on EC2 instances
- [ ] Tested secret loading in Rails console
- [ ] Documented rotation procedures
- [ ] Set up CloudWatch monitoring
- [ ] Trained team on secret access

---

## Next Steps

1. **Bundle Installation**: `bundle install` to add AWS SDK gems
2. **Local Testing**: Test secret loading with .env file
3. **Production Deployment**: Deploy Terraform, then applications
4. **Monitoring**: Set up CloudWatch alerts for secret access failures
5. **Documentation**: Keep this guide updated as new secrets are added
