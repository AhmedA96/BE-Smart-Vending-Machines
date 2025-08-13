# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ContactUsRequests API', type: :request do
  describe 'POST /api/v1/contact-us' do
    let(:valid_params) do
      {
        contact: {
          full_name: 'VNDG',
          email: 'vndg@example.com',
          company_name: 'VNDG',
          phone_number: '+201234567890'
        }
      }
    end

    it 'creates a contact us request' do
      expect do
        post '/api/v1/contact-us', params: valid_params
      end.to change(ContactUsRequest, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it 'returns validation errors if required fields are missing' do
      post '/api/v1/contact-us', params: { contact: { full_name: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      json_response = response.parsed_body

      expect(json_response['errors']).to include(
        'full_name' => include("can't be blank"),
        'email' => include("can't be blank"),
        'phone_number' => include("can't be blank"),
        'company_name' => include("can't be blank")
      )
    end

    it 'returns validation error for invalid email format' do
      invalid_params = valid_params.deep_merge(
        contact: { email: 'invalid-email' }
      )

      post '/api/v1/contact-us', params: invalid_params

      expect(response).to have_http_status(:unprocessable_content)
      json_response = response.parsed_body
      expect(json_response['errors']['email']).to include('is invalid')
    end

    it 'returns validation error for invalid phone number format' do
      invalid_params = valid_params.deep_merge(
        contact: { phone_number: 'invalid-phone' }
      )

      post '/api/v1/contact-us', params: invalid_params

      expect(response).to have_http_status(:unprocessable_content)
      json_response = response.parsed_body
      expect(json_response['errors']['phone_number']).to include('is invalid')
    end
  end
end
