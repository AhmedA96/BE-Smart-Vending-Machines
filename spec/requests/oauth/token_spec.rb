# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'OAuth Token Endpoints', type: :request do
  path '/oauth/token' do
    post 'Generate access token' do
      tags 'OAuth'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :token_params, in: :body, schema: {
        type: :object,
        properties: {
          grant_type: { type: :string, example: 'password' },
          mobile_number: { type: :string, example: '201234567890' },
          password: { type: :string, example: 'Password@!123' }
        },
        required: %w[grant_type mobile_number password]
      }

      let(:user) { create(:user, password: 'Password@!123') }
      let(:token_params) do
        {
          grant_type: 'password',
          mobile_number: user.mobile_number,
          password: 'Password@!123'
        }
      end

      response '200', 'token generated' do
        run_test! do
          json_response = response.parsed_body
          expect(json_response['access_token']).to be_present
          expect(json_response['token_type']).to eq('Bearer')
          expect(json_response['created_at']).to be_present
          expect(json_response['refresh_token']).to be_present
        end
      end

      response '400', 'invalid credentials' do
        let(:token_params) do
          {
            grant_type: 'password',
            mobile_number: user.mobile_number,
            password: 'wrong_password'
          }
        end

        run_test! do
          json_response = response.parsed_body
          expect(json_response['error']).to eq('The credentials you entered are incorrect. Please check your mobile number and password.') # rubocop:disable Layout/LineLength
        end
      end
    end
  end

  path '/oauth/token' do
    post 'Refresh access token' do
      tags 'OAuth'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :refresh_params, in: :body, schema: {
        type: :object,
        properties: {
          grant_type: { type: :string, example: 'refresh_token' },
          refresh_token: { type: :string, example: 'valid_refresh_token' }
        },
        required: %w[grant_type refresh_token]
      }

      let(:user) { create(:user) }
      let(:access_token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
      let(:refresh_params) do
        {
          grant_type: 'refresh_token',
          refresh_token: access_token.refresh_token
        }
      end

      response '200', 'token refreshed' do
        run_test! do
          json_response = response.parsed_body
          expect(json_response['access_token']).to be_present
          expect(json_response['token_type']).to eq('Bearer')
          expect(json_response['expires_in']).to be_present
          expect(json_response['refresh_token']).to be_present
        end
      end

      response '400', 'invalid refresh token' do
        let(:refresh_params) do
          {
            grant_type: 'refresh_token',
            refresh_token: 'invalid_refresh_token'
          }
        end

        run_test! do
          json_response = response.parsed_body
          expect(json_response['error']).to include('invalid_grant')
        end
      end
    end
  end

  path '/oauth/revoke' do
    post 'Revoke token' do
      tags 'OAuth'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :revoke_params, in: :body, schema: {
        type: :object,
        properties: {
          token: { type: :string, example: 'valid_token' }
        },
        required: %w[token]
      }

      let(:user) { create(:user) }
      let(:access_token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
      let(:revoke_params) do
        {
          token: access_token.token
        }
      end

      response '200', 'token revoked' do
        run_test! do
          expect(access_token.reload.revoked?).to be true
        end
      end
    end
  end
end
