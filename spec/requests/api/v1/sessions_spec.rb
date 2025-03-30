# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'User Sessions', type: :request do
  path '/api/v1/users/login' do
    post 'User login' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: 'user@example.com' },
          password: { type: :string, example: 'Password@123' }
        },
        required: %w[email password]
      }

      let(:user) { create(:user, email: 'test@example.com', password: 'Password@123') }

      response '201', 'login successful' do
        let(:credentials) { { email: user.email, password: 'Password@123' } }
        run_test! do
          expect(response).to have_http_status(:created)
        end
      end

      response '422', 'invalid credentials' do
        let(:credentials) { { email: user.email, password: 'wrongpassword' } }
        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('Invalid email or password')
        end
      end

      response '422', 'non-existent user' do
        let(:credentials) { { email: 'unknown@example.com', password: 'password123' } }
        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('Invalid email or password')
        end
      end
    end
  end
end
