#!/usr/bin/env ruby
# frozen_string_literal: true

# Populate .kamal/secrets.production by fetching from AWS Secrets Manager
# This script is run BEFORE kamal deploy to populate the secrets file with actual values

require 'json'
require 'open3'

SECRETS_FILE = '.kamal/secrets.production'
REGION = 'me-central-1'

def fetch_secret(secret_id, key = nil)
  cmd = [
    'aws', 'secretsmanager', 'get-secret-value',
    '--secret-id', secret_id,
    '--region', REGION,
    '--query', 'SecretString',
    '--output', 'text'
  ]

  stdout, stderr, status = Open3.capture3(*cmd)

  raise "Failed to fetch secret '#{secret_id}': #{stderr}" unless status.success?

  secret_value = stdout.strip

  # If key is specified, parse JSON and extract that key
  if key
    begin
      secret_json = JSON.parse(secret_value)
      secret_json[key] || raise("Key '#{key}' not found in secret '#{secret_id}'")
    rescue JSON::ParserError => e
      raise "Failed to parse secret '#{secret_id}' as JSON: #{e.message}"
    end
  else
    secret_value
  end
end

begin
  puts 'Fetching production secrets from AWS Secrets Manager...'

  # Fetch all required secrets
  puts '  - Fetching GitHub Container Registry token...'
  registry_password = fetch_secret('vending-system/production/github-container-registry-token')

  puts '  - Fetching database credentials...'
  db_creds = fetch_secret('vending-system/production/db/credentials')
  postgres_user = JSON.parse(db_creds)['username']
  postgres_password = JSON.parse(db_creds)['password']

  puts '  - Fetching Rails master key...'
  rails_master_key = fetch_secret('vending-system/production/app/secrets', 'rails_master_key')

  puts '  - Fetching Rails secret key base...'
  rails_secret_key_base = fetch_secret('vending-system/production/app/secrets', 'rails_secret_key_base')

  puts '  - Fetching JWT secret...'
  jwt_secret = fetch_secret('vending-system/production/app/secrets', 'jwt_secret')

  puts '  - Fetching Cloudflare credentials...'
  app_secrets = fetch_secret('vending-system/production/app/secrets')
  app_secrets_json = JSON.parse(app_secrets)
  cloudflare_token = app_secrets_json.dig('cloudflare', 'api_token')
  cloudflare_zone_id = app_secrets_json.dig('cloudflare', 'zone_id')

  puts '  - Fetching AWS S3 configuration...'
  s3_media_bucket = app_secrets_json.dig('aws', 's3_media_bucket')
  s3_backup_bucket = app_secrets_json.dig('aws', 's3_backup_bucket')
  aws_region = app_secrets_json.dig('aws', 'region')

  # Write to secrets file
  puts "\nWriting secrets to #{SECRETS_FILE}..."
  File.write(SECRETS_FILE, <<~SECRETS)
    # Kamal Production Secrets for AWS Infrastructure
    # ================================================
    # Auto-populated by scripts/populate-production-secrets.rb
    # Generated at: #{Time.now.to_f}

    # Container Registry
    KAMAL_REGISTRY_PASSWORD=#{registry_password}

    # Database
    POSTGRES_USER=#{postgres_user}
    POSTGRES_PASSWORD=#{postgres_password}

    # Rails Secrets
    RAILS_MASTER_KEY=#{rails_master_key}
    SECRET_KEY_BASE=#{rails_secret_key_base}
    JWT_SECRET=#{jwt_secret}

    # AWS S3 Configuration
    AWS_REGION=#{aws_region}
    AWS_S3_MEDIA_BUCKET=#{s3_media_bucket}
    AWS_S3_BACKUP_BUCKET=#{s3_backup_bucket}

    # Cloudflare
    CLOUDFLARE_API_TOKEN=#{cloudflare_token}
    CLOUDFLARE_ZONE_ID=#{cloudflare_zone_id}
  SECRETS

  File.chmod(0o600, SECRETS_FILE)

  puts '✓ Production secrets loaded successfully!'
  puts "\nReady to deploy: kamal deploy -d production"
rescue StandardError => e
  puts "\n❌ ERROR: #{e.message}"
  exit 1
end
