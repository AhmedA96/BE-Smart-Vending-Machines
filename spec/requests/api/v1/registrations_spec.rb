# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'User Registration', type: :request do
  path '/api/v1/users/signup' do
    post 'Register a new user' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          password: { type: :string, example: 'Password@!123' },
          mobile_number: { type: :string, example: '+201234567890' }
        },
        required: %w[password mobile_number]
      }
      let(:existing_user) { create(:user, mobile_number: '+201234567890') }
      let(:valid_attributes) do
        {
          password: 'Password@!123',
          mobile_number: '+201234567890'
        }
      end

      let(:invalid_attributes) do
        {
          mobile_number: '',
          password: 'short'
        }
      end

      describe 'POST /api/v1/users/signup' do
        context 'with valid parameters' do
          response '201', 'user created' do
            let(:user) { { user: valid_attributes } }
            run_test! do
              expect(User.last.mobile_number).to eq(valid_attributes[:mobile_number])
            end
          end
        end

        context 'with invalid parameters' do
          response '422', 'invalid request' do
            let(:user) { { user: invalid_attributes } }
            run_test! do
              expect(response.body).to include("can't be blank")
            end
          end
        end

        context 'with valid but taken mobile number' do
          response '422', 'mobile number already taken' do
            before { existing_user }
            let(:user) { { user: valid_attributes } }
            run_test! do
              json_response = response.parsed_body
              expect(json_response['errors'].first['mobile_number']).to include('has already been taken')
            end
          end
        end
      end
    end
  end
end
