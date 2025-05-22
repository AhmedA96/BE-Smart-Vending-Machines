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

      expect(response).to have_http_status(:no_content)
    end

    it 'returns error if required fields are missing' do
      post '/api/v1/contact-us', params: { contact: { full_name: '' } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
