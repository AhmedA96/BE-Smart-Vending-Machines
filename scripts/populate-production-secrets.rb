#!/usr/bin/env ruby

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

  if !status.success?
    raise "Failed to fetch secret '#{secret_id}': #{stderr}"
  end

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
  puts "Fetching production secrets from AWS Secrets Manager..."

  # Fetch all required secrets
  puts "  - Fetching GitHub Container Registry token..."
  registry_password = fetch_secret('vending-system/production/github-container-registry-token')

  puts "  - Fetching database credentials..."
  db_creds = fetch_secret('vending-system/production/db/credentials')
  postgres_user = JSON.parse(db_creds)['username']
  postgres_password = JSON.parse(db_creds)['password']

  puts "  - Fetching Rails master key..."
  rails_master_key = fetch_secret('vending-system/production/app/secrets', 'rails_master_key')

  # Write to secrets file
  puts "\nWriting secrets to #{SECRETS_FILE}..."
  File.write(SECRETS_FILE, <<~SECRETS)
    # Kamal Production Secrets for AWS Infrastructure
    # ================================================
    # Auto-populated by scripts/populate-production-secrets.rb
    # Generated at: #{Time.now}

    KAMAL_REGISTRY_PASSWORD=#{registry_password}
    POSTGRES_USER=#{postgres_user}
    POSTGRES_PASSWORD=#{postgres_password}
    RAILS_MASTER_KEY=#{rails_master_key}
  SECRETS

  File.chmod(0o600, SECRETS_FILE)

  puts "✓ Production secrets loaded successfully!"
  puts "\nReady to deploy: kamal deploy -d production"

rescue StandardError => e
  puts "\n❌ ERROR: #{e.message}"
  exit 1
end
