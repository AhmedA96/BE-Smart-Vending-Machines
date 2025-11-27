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
          mobile_number: { type: :string, example: '+201234567890' },
          password: { type: :string, example: 'Password@123' }
        },
        required: %w[mobile_number password]
      }

      let(:user) { create(:user, mobile_number: '+201234567890', password: 'Password@123') }

      response '201', 'login successful' do
        let(:credentials) { { mobile_number: user.mobile_number, password: 'Password@123' } }
        run_test! do
          expect(response).to have_http_status(:created)
        end
      end

      response '422', 'invalid credentials' do
        let(:credentials) { { mobile_number: user.mobile_number, password: 'wrongpassword' } }
        run_test! do
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include('Invalid mobile number or password')
        end
      end

      response '422', 'non-existent user' do
        let(:credentials) { { mobile_number: '', password: 'password123' } }
        run_test! do
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include('Invalid mobile number or password')
        end
      end
    end
  end
end
