require 'rails_helper'

RSpec.describe 'ContactUsRequests API', type: :request do
  describe 'POST /api/v1/contact-us' do
    let(:contact) { create(:contact_us_request) }

    it 'creates a contact us request' do
      expect do
        post '/api/v1/contact-us', params: contact
      end.to change(ContactUsRequest, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it 'returns error if required fields are missing' do
      post '/api/v1/contact_us', params: { contact: { full_name: '' } }

      expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:bad_request)
    end
  end
end
