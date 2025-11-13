# frozen_string_literal: true

# config/initializers/secrets_manager.rb
#
# Loads secrets from AWS Secrets Manager on Rails startup
# Populates ENV variables for application to use
#
# This initializer runs in all environments:
# - production: Uses real secrets from AWS Secrets Manager
# - staging: Uses real secrets (different secret names)
# - development: Falls back to .env file if Secrets Manager not available
# - test: Uses ENV variables set in test setup

# ============================================
# Helper Methods (must be defined before use)
# ============================================

# Determine if we should load from Secrets Manager
# Only load if:
# 1. Environment variable AWS_LOAD_SECRETS is explicitly true, OR
# 2. Running in production/staging with an EC2 instance profile
def should_load_from_secrets_manager?
  return true if ENV['AWS_LOAD_SECRETS'] == 'true'
  return false if Rails.env.local?

  # For production/staging, check if we have AWS credentials
  aws_credentials?
end

# Check if AWS credentials are available (EC2 instance profile)
def aws_credentials?
  # EC2 instance profile provides credentials via environment or metadata
  ENV.key?('AWS_REGION') || ENV.key?('AWS_DEFAULT_REGION') ||
    ENV.key?('AWS_ACCESS_KEY_ID') || ENV.key?('AWS_IAM_ROLE')
rescue StandardError
  false
end

# Load database credentials from Secrets Manager
def load_database_secrets
  secret_name = "#{ENV['SECRETS_PROJECT'] || 'vending-system'}/#{Rails.env}/db/credentials"

  Rails.logger.info("Loading database credentials from: #{secret_name}")

  db_creds = SecretsManagerService.get_secret(secret_name)

  ENV['DATABASE_HOST'] = db_creds['host']
  ENV['DATABASE_USER'] = db_creds['username']
  ENV['DATABASE_PASSWORD'] = db_creds['password']
  ENV['DATABASE_PORT'] = db_creds['port'].to_s
  ENV['DATABASE_NAME'] = db_creds['dbname']

  Rails.logger.info("✓ Database: #{db_creds['host']}:#{db_creds['port']}/#{db_creds['dbname']}")
rescue SecretsManagerService::SecretNotFound
  # If secret not found, check if DATABASE_URL is already set (e.g., from CloudFormation)
  raise if ENV['DATABASE_URL'].blank?

  Rails.logger.warn('Secret not found but DATABASE_URL is set, using existing URL')
end

# Load Redis credentials from Secrets Manager
def load_redis_secrets
  secret_name = "#{ENV['SECRETS_PROJECT'] || 'vending-system'}/#{Rails.env}/redis/credentials"

  Rails.logger.info("Loading Redis credentials from: #{secret_name}")

  redis_creds = SecretsManagerService.get_secret(secret_name)

  ENV['REDIS_HOST'] = redis_creds['host']
  ENV['REDIS_PORT'] = redis_creds['port'].to_s

  Rails.logger.info("✓ Redis: #{redis_creds['host']}:#{redis_creds['port']}")
rescue SecretsManagerService::SecretNotFound
  # Redis is optional, only required if using Kredis/Sidekiq
  if ENV['REDIS_URL'].present?
    Rails.logger.warn('Redis secret not found but REDIS_URL is set, using existing URL')
  else
    Rails.logger.warn('Redis secret not found and REDIS_URL not set - Redis features will be unavailable')
  end
end

# Load application secrets from Secrets Manager
def load_application_secrets
  secret_name = "#{ENV['SECRETS_PROJECT'] || 'vending-system'}/#{Rails.env}/app/secrets"

  Rails.logger.info("Loading application secrets from: #{secret_name}")

  app_secrets = SecretsManagerService.get_secret(secret_name)

  load_rails_secrets(app_secrets)
  load_jwt_secrets(app_secrets)
  load_supplier_api_secrets(app_secrets)
  load_external_service_secrets(app_secrets)

  Rails.logger.info("✓ Application secrets loaded (#{app_secrets.keys.count} keys)")
rescue SecretsManagerService::SecretNotFound
  Rails.logger.error('Application secrets not found in Secrets Manager')
  raise
end

# Load Rails-specific secrets
def load_rails_secrets(app_secrets)
  ENV['RAILS_MASTER_KEY'] = app_secrets['rails_master_key']
  ENV['SECRET_KEY_BASE'] = app_secrets['rails_secret_key_base']
end

# Load JWT authentication secrets
def load_jwt_secrets(app_secrets)
  ENV['JWT_SECRET'] = app_secrets['jwt_secret']
end

# Load supplier API secrets
def load_supplier_api_secrets(app_secrets)
  return unless app_secrets['api_keys']&.key?('supplier_api_key')

  ENV['SUPPLIER_API_KEY'] = app_secrets['api_keys']['supplier_api_key']
  ENV['SUPPLIER_API_SECRET'] = app_secrets['api_keys']['supplier_api_secret']
end

# Load external service secrets
def load_external_service_secrets(app_secrets)
  return unless app_secrets['external_services']

  external_services = app_secrets['external_services']

  if external_services.key?('payment_provider_key')
    ENV['PAYMENT_PROVIDER_KEY'] =
      external_services['payment_provider_key']
  end
  ENV['SMS_PROVIDER_KEY'] = external_services['sms_provider_key'] if external_services.key?('sms_provider_key')
end

# ============================================
# Load Secrets on Rails Startup
# ============================================

Rails.logger.info('Initializing AWS Secrets Manager integration...')

# Only load from Secrets Manager if running on AWS (EC2 instance has IAM role)
# Development/local environment uses .env file (dotenv-rails)
if should_load_from_secrets_manager?
  begin
    load_database_secrets
    load_redis_secrets
    load_application_secrets

    Rails.logger.info('✓ All secrets loaded successfully from AWS Secrets Manager')
  rescue SecretsManagerService::SecretNotFound => e
    Rails.logger.error("✗ Secret not found: #{e.message}")
    raise "Failed to load required secrets: #{e.message}"
  rescue SecretsManagerService::DecryptionError => e
    Rails.logger.error("✗ KMS decryption failed: #{e.message}")
    raise "Failed to decrypt secrets: #{e.message}"
  rescue SecretsManagerService::ServiceUnavailable => e
    Rails.logger.error("✗ AWS Secrets Manager unavailable: #{e.message}")
    raise "AWS Secrets Manager temporarily unavailable: #{e.message}"
  end
else
  Rails.logger.info('Using .env file for secrets (development/test environment)')
end
