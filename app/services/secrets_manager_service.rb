# frozen_string_literal: true

# SecretsManagerService
# Handles secure retrieval and caching of secrets from AWS Secrets Manager
# All secrets are encrypted with KMS and cached in memory for performance
#
# Usage:
#   credentials = SecretsManagerService.get_secret('vending-system/production/db/credentials')
#   db_host = credentials['host']
#
#   # With error handling
#   begin
#     secret = SecretsManagerService.get_secret('path/to/secret', retries: 3)
#   rescue SecretsManagerService::SecretNotFound => e
#     Rails.logger.error("Secret not found: #{e.message}")
#   rescue SecretsManagerService::DecryptionError => e
#     Rails.logger.error("KMS decryption failed: #{e.message}")
#   end

class SecretsManagerService
  # Custom exceptions
  class SecretError < StandardError; end
  class SecretNotFound < SecretError; end
  class DecryptionError < SecretError; end
  class ServiceUnavailable < SecretError; end

  # Cache secrets in memory (thread-safe) - using instance variables on singleton
  @secret_cache = Concurrent::Map.new
  @cache_lock = Mutex.new

  class << self
    # Retrieve a secret from AWS Secrets Manager
    # @param secret_id [String] The secret identifier (e.g., 'vending-system/production/db/credentials')
    # @param options [Hash] Additional options
    # @option options [Integer] :retries (3) Number of retry attempts
    # @option options [Integer] :cache_ttl (3600) Cache time-to-live in seconds
    # @option options [Boolean] :use_cache (true) Whether to use cached values
    # @return [Hash] Parsed JSON secret value
    # @raise [SecretNotFound] If secret doesn't exist
    # @raise [DecryptionError] If KMS decryption fails
    # @raise [ServiceUnavailable] If AWS service is unavailable
    def get_secret(secret_id, **options)
      use_cache = options.fetch(:use_cache, true)

      # Return cached value if available
      return get_cached_secret(secret_id) if use_cache && cached?(secret_id)

      # Attempt to retrieve secret with retries
      secret_value = fetch_with_retries(secret_id, options[:retries] || 3)

      # Parse and cache the secret
      parsed_secret = parse_secret(secret_value)
      cache_secret(secret_id, parsed_secret, options[:cache_ttl])

      parsed_secret
    end

    # Retrieve multiple secrets in parallel (more efficient than individual calls)
    # @param secret_ids [Array<String>] Array of secret identifiers
    # @param options [Hash] Additional options (same as get_secret)
    # @return [Hash] Map of secret_id => parsed_value
    def get_secrets(secret_ids, **)
      secret_ids.index_with do |secret_id|
        get_secret(secret_id, **)
      end
    end

    # Clear specific or all cached secrets
    # @param secret_id [String, nil] Specific secret to clear, or nil to clear all
    def clear_cache(secret_id = nil)
      @cache_lock.synchronize do
        if secret_id
          @secret_cache.delete(secret_id)
        else
          @secret_cache.clear
        end
      end
    end

    # Get cache statistics (for monitoring/debugging)
    # @return [Hash] Cache statistics
    def cache_stats
      @cache_lock.synchronize do
        {
          cached_secrets: @secret_cache.size,
          cache_keys: @secret_cache.keys
        }
      end
    end

    private

    # Fetch secret with retry logic
    def fetch_with_retries(secret_id, max_retries)
      secret_value = nil
      last_error = nil

      max_retries.times do |attempt|
        secret_value = fetch_from_secrets_manager(secret_id)
        break
      rescue ServiceUnavailable => e
        last_error = e
        wait_time = exponential_backoff(attempt)
        sleep(wait_time) if attempt < max_retries - 1
      end

      raise last_error if secret_value.nil? && last_error

      secret_value
    end

    # Fetch secret directly from AWS Secrets Manager
    def fetch_from_secrets_manager(secret_id)
      client = aws_secrets_manager_client

      begin
        response = client.get_secret_value(secret_id: secret_id)

        if response.secret_string
          response.secret_string
        elsif response.secret_binary
          response.secret_binary
        else
          raise SecretError, "Secret #{secret_id} has no value"
        end
      rescue Aws::SecretsManager::Errors::ResourceNotFoundException
        raise SecretNotFound, "Secret '#{secret_id}' not found in AWS Secrets Manager"
      rescue Aws::SecretsManager::Errors::InvalidRequestException => e
        raise SecretNotFound, "Invalid secret ID: #{e.message}"
      rescue Aws::SecretsManager::Errors::DecryptionFailure
        raise DecryptionError, "Failed to decrypt secret '#{secret_id}' using KMS key"
      rescue Aws::SecretsManager::Errors::ServiceError => e
        raise ServiceUnavailable, "AWS Secrets Manager temporarily unavailable: #{e.message}"
      end
    end

    # Initialize AWS Secrets Manager client
    def aws_secrets_manager_client
      region = ENV['AWS_REGION'] || ENV['AWS_DEFAULT_REGION'] || 'me-south-1'

      @aws_secrets_manager_client ||= Aws::SecretsManager::Client.new(region: region)
    end

    # Parse secret value (JSON string to Hash)
    def parse_secret(secret_string)
      JSON.parse(secret_string)
    rescue JSON::ParserError => e
      raise SecretError, "Failed to parse secret as JSON: #{e.message}"
    end

    # Check if secret is cached and not expired
    def cached?(secret_id)
      @cache_lock.synchronize do
        cache_entry = @secret_cache[secret_id]
        cache_entry && !cache_entry[:expires_at].past?
      end
    end

    # Retrieve cached secret
    def get_cached_secret(secret_id)
      @cache_lock.synchronize do
        @secret_cache[secret_id][:value]
      end
    end

    # Store secret in cache with TTL
    def cache_secret(secret_id, secret_value, ttl = nil)
      ttl ||= 3600 # Default 1 hour
      expires_at = Time.current + ttl.seconds

      @cache_lock.synchronize do
        @secret_cache[secret_id] = {
          value: secret_value,
          expires_at: expires_at
        }
      end

      Rails.logger.info("Cached secret: #{secret_id} (expires at #{expires_at})")
    end

    # Exponential backoff for retries: 1s, 2s, 4s, 8s...
    def exponential_backoff(attempt)
      2**attempt
    end
  end
end
