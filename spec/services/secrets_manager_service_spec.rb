# frozen_string_literal: true

# Simple unit test for SecretsManagerService without full Rails environment
require 'spec_helper'
require 'json'
require 'concurrent'
require 'aws-sdk-secretsmanager'
require 'active_support/all'

# Mock minimal Rails environment if not already loaded
unless defined?(Rails)
  module Rails
    def self.logger
      @logger ||= Logger.new($stdout)
    end
  end
end

# Load the service directly
require_relative '../../app/services/secrets_manager_service'

RSpec.describe SecretsManagerService do
  before do
    # Clear cache before each test
    SecretsManagerService.clear_cache
  end

  describe '.get_secret' do
    let(:secret_name) { 'test-secret' }
    let(:secret_value) { { 'username' => 'admin', 'password' => 'secret123' }.to_json }

    context 'when secret exists' do
      before do
        allow_any_instance_of(Aws::SecretsManager::Client).to receive(:get_secret_value)
          .with(secret_id: secret_name)
          .and_return(
            Aws::SecretsManager::Types::GetSecretValueResponse.new(
              secret_string: secret_value
            )
          )
      end

      it 'returns parsed secret' do
        result = SecretsManagerService.get_secret(secret_name)
        expect(result).to eq({ 'username' => 'admin', 'password' => 'secret123' })
      end

      it 'caches the secret' do
        SecretsManagerService.get_secret(secret_name)

        # Should use cache on second call
        expect_any_instance_of(Aws::SecretsManager::Client).not_to receive(:get_secret_value)

        result = SecretsManagerService.get_secret(secret_name)
        expect(result).to eq({ 'username' => 'admin', 'password' => 'secret123' })
      end
    end

    context 'when secret not found' do
      before do
        allow_any_instance_of(Aws::SecretsManager::Client).to receive(:get_secret_value)
          .and_raise(Aws::SecretsManager::Errors::ResourceNotFoundException.new(nil, 'not found'))
      end

      it 'raises SecretNotFound error' do
        expect do
          SecretsManagerService.get_secret(secret_name)
        end.to raise_error(SecretsManagerService::SecretNotFound)
      end
    end

    context 'when KMS decryption fails' do
      before do
        allow_any_instance_of(Aws::SecretsManager::Client).to receive(:get_secret_value)
          .and_raise(Aws::SecretsManager::Errors::DecryptionFailure.new(nil, 'decrypt failed'))
      end

      it 'raises DecryptionError' do
        expect do
          SecretsManagerService.get_secret(secret_name)
        end.to raise_error(SecretsManagerService::DecryptionError)
      end
    end

    context 'when service is temporarily unavailable' do
      before do
        allow_any_instance_of(Aws::SecretsManager::Client).to receive(:get_secret_value)
          .and_raise(Aws::SecretsManager::Errors::ServiceError.new(nil, 'service unavailable'))
      end

      it 'retries with exponential backoff' do
        # Should retry 3 times by default
        expect_any_instance_of(Aws::SecretsManager::Client)
          .to receive(:get_secret_value).exactly(3).times
          .and_raise(Aws::SecretsManager::Errors::ServiceError.new(nil, 'unavailable'))

        expect do
          SecretsManagerService.get_secret(secret_name, retries: 3)
        end.to raise_error(SecretsManagerService::ServiceUnavailable)
      end
    end

    context 'with cache disabled' do
      it 'fetches secret each time' do
        call_count = 0
        allow_any_instance_of(Aws::SecretsManager::Client).to receive(:get_secret_value) do
          call_count += 1
          Aws::SecretsManager::Types::GetSecretValueResponse.new(
            secret_string: secret_value
          )
        end

        SecretsManagerService.get_secret(secret_name, use_cache: false)
        first_count = call_count

        SecretsManagerService.get_secret(secret_name, use_cache: false)
        second_count = call_count

        # Should have called AWS service twice (not cached)
        expect(first_count).to eq(1)
        expect(second_count).to eq(2)
      end
    end

    context 'with custom cache TTL' do
      before do
        allow_any_instance_of(Aws::SecretsManager::Client).to receive(:get_secret_value)
          .and_return(
            Aws::SecretsManager::Types::GetSecretValueResponse.new(
              secret_string: secret_value
            )
          )
      end

      it 'caches secret with specified TTL' do
        SecretsManagerService.get_secret(secret_name, cache_ttl: 60)

        stats = SecretsManagerService.cache_stats
        expect(stats[:cached_secrets]).to eq(1)
      end
    end
  end

  describe '.get_secrets' do
    let(:secret_names) { %w[secret-1 secret-2] }
    let(:secret_values) do
      {
        'secret-1' => { 'key' => 'value1' }.to_json,
        'secret-2' => { 'key' => 'value2' }.to_json
      }
    end

    before do
      allow_any_instance_of(Aws::SecretsManager::Client).to receive(:get_secret_value) do |_instance, args|
        secret_id = args[:secret_id]
        Aws::SecretsManager::Types::GetSecretValueResponse.new(
          secret_string: secret_values[secret_id]
        )
      end
    end

    it 'retrieves multiple secrets' do
      result = SecretsManagerService.get_secrets(secret_names)

      expect(result['secret-1']).to eq({ 'key' => 'value1' })
      expect(result['secret-2']).to eq({ 'key' => 'value2' })
    end
  end

  describe '.clear_cache' do
    let(:secret_name) { 'test-secret' }
    let(:secret_value) { { 'key' => 'value' }.to_json }

    before do
      allow_any_instance_of(Aws::SecretsManager::Client).to receive(:get_secret_value)
        .and_return(
          Aws::SecretsManager::Types::GetSecretValueResponse.new(
            secret_string: secret_value
          )
        )
    end

    context 'clearing specific secret' do
      it 'removes secret from cache' do
        SecretsManagerService.get_secret(secret_name)

        stats = SecretsManagerService.cache_stats
        expect(stats[:cached_secrets]).to eq(1)

        SecretsManagerService.clear_cache(secret_name)

        stats = SecretsManagerService.cache_stats
        expect(stats[:cached_secrets]).to eq(0)
      end
    end

    context 'clearing all secrets' do
      it 'removes all cached secrets' do
        SecretsManagerService.get_secret('secret-1')
        SecretsManagerService.get_secret('secret-2')

        stats = SecretsManagerService.cache_stats
        expect(stats[:cached_secrets]).to eq(2)

        SecretsManagerService.clear_cache

        stats = SecretsManagerService.cache_stats
        expect(stats[:cached_secrets]).to eq(0)
      end
    end
  end

  describe '.cache_stats' do
    let(:secret_name) { 'test-secret' }
    let(:secret_value) { { 'key' => 'value' }.to_json }

    before do
      allow_any_instance_of(Aws::SecretsManager::Client).to receive(:get_secret_value)
        .and_return(
          Aws::SecretsManager::Types::GetSecretValueResponse.new(
            secret_string: secret_value
          )
        )
    end

    it 'returns cache statistics' do
      SecretsManagerService.get_secret(secret_name)

      stats = SecretsManagerService.cache_stats

      expect(stats).to include(
        cached_secrets: 1,
        cache_keys: [secret_name]
      )
    end
  end

  describe 'error handling' do
    context 'invalid JSON in secret' do
      before do
        allow_any_instance_of(Aws::SecretsManager::Client).to receive(:get_secret_value)
          .and_return(
            Aws::SecretsManager::Types::GetSecretValueResponse.new(
              secret_string: 'not valid json'
            )
          )
      end

      it 'raises SecretError' do
        expect do
          SecretsManagerService.get_secret('test-secret')
        end.to raise_error(SecretsManagerService::SecretError)
      end
    end
  end
end
