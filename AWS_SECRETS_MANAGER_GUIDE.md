# AWS Secrets Manager Integration Guide

Documentation for AWS Secrets Manager integration in the Rails application.

---

## Implementation Overview

The application includes two main components:

1. **SecretsManagerService** (`app/services/secrets_manager_service.rb`)

   - Handles fetching secrets from AWS Secrets Manager
   - Implements thread-safe caching with configurable TTL
   - Provides retry logic with exponential backoff
   - Custom exception types for different failure modes

2. **Secrets Initializer** (`config/initializers/secrets_manager.rb`)
   - Loads secrets on Rails startup
   - Auto-detects AWS environment
   - Populates ENV variables with loaded secrets
   - Handles optional secrets gracefully

---

## Accessing Secrets in Code

### Method 1: Using ENV Variables

Secrets are automatically loaded into ENV variables by the initializer:

```ruby
ENV['DATABASE_HOST']
ENV['DATABASE_USER']
ENV['DATABASE_PASSWORD']
ENV['DATABASE_PORT']
ENV['DATABASE_NAME']
ENV['REDIS_HOST']
ENV['REDIS_PORT']
ENV['RAILS_MASTER_KEY']
ENV['SECRET_KEY_BASE']
ENV['JWT_SECRET']
ENV['SUPPLIER_API_KEY']
ENV['SUPPLIER_API_SECRET']
ENV['PAYMENT_PROVIDER_KEY']
ENV['SMS_PROVIDER_KEY']
```

### Method 2: Direct Service Call

For dynamic secret retrieval:

```ruby
begin
  secret = SecretsManagerService.get_secret(
    'vending-system/production/app/secrets'
  )
  api_key = secret['api_keys']['supplier_api_key']
rescue SecretsManagerService::SecretNotFound => e
  Rails.logger.error("Secret not found: #{e.message}")
end
```

---

## Error Handling

### Custom Exceptions

The SecretsManagerService provides specific exceptions:

- **SecretNotFound**: Secret doesn't exist
- **DecryptionError**: KMS decryption failed
- **ServiceUnavailable**: AWS temporarily unavailable
- **SecretError**: Generic error (parent class)

### Example Error Handling

```ruby
begin
  SecretsManagerService.get_secret('my-secret')
rescue SecretsManagerService::SecretNotFound => e
  Rails.logger.error("Secret missing: #{e.message}")
rescue SecretsManagerService::DecryptionError => e
  Rails.logger.error("KMS decryption failed: #{e.message}")
rescue SecretsManagerService::ServiceUnavailable => e
  Rails.logger.error("AWS temporarily unavailable: #{e.message}")
  # Service auto-retries with exponential backoff
end
```

---

## Cache Behavior

Secrets are cached in memory with configurable TTL:

```ruby
# Fetch secret (cached for 1 hour by default)
secret = SecretsManagerService.get_secret('my-secret')

# Override cache TTL (5 minutes)
secret = SecretsManagerService.get_secret('my-secret', cache_ttl: 300)

# Disable cache
secret = SecretsManagerService.get_secret('my-secret', use_cache: false)

# Clear specific secret from cache
SecretsManagerService.clear_cache('my-secret')

# Clear entire cache
SecretsManagerService.clear_cache

# Check cache stats
stats = SecretsManagerService.cache_stats
# => {:cached_secrets=>2, :cache_keys=>["vending-system/production/db/credentials", ...]}
```

### Retry Logic

The service automatically retries failed requests with exponential backoff:

- Attempt 1: Immediate
- Attempt 2: Wait 1 second
- Attempt 3: Wait 2 seconds
- Attempt 4: Wait 4 seconds (etc.)

---

## Service Architecture

### SecretsManagerService

Located in `app/services/secrets_manager_service.rb`

**Public Methods:**

```ruby
SecretsManagerService.get_secret(secret_id, **options)
# Fetch a secret from AWS Secrets Manager
# Options:
#   - retries: (3) Number of retry attempts
#   - cache_ttl: (3600) Cache time-to-live in seconds
#   - use_cache: (true) Whether to use cached values

SecretsManagerService.get_secrets(secret_ids, **options)
# Fetch multiple secrets (same options as get_secret)

SecretsManagerService.clear_cache(secret_id = nil)
# Clear specific secret or entire cache

SecretsManagerService.cache_stats
# Get cache statistics for monitoring
```

**Exception Classes:**

- `SecretError` - Generic error (parent)
- `SecretNotFound` - Secret doesn't exist
- `DecryptionError` - KMS decryption failed
- `ServiceUnavailable` - AWS temporarily unavailable

### Secrets Initializer

Located in `config/initializers/secrets_manager.rb`

**Behavior:**

1. Checks if `AWS_LOAD_SECRETS` is true or running in production/staging
2. Loads database credentials → ENV['DATABASE_*']
3. Loads Redis credentials → ENV['REDIS_*']
4. Loads application secrets → ENV['RAILS_MASTER_KEY'], ENV['JWT_SECRET'], etc.
5. Logs each step for verification

**Helper Methods:**

- `should_load_from_secrets_manager?` - Determines if loading is needed
- `aws_credentials?` - Checks for AWS environment
- `load_database_secrets` - Loads database credentials
- `load_redis_secrets` - Loads Redis credentials (optional)
- `load_rails_secrets` - Loads Rails-specific secrets
- `load_jwt_secrets` - Loads JWT authentication secret
- `load_supplier_api_secrets` - Loads supplier API keys
- `load_external_service_secrets` - Loads payment/SMS provider keys
