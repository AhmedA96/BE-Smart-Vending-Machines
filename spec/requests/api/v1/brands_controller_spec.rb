# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::BrandsController, type: :request do
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: nil) }

  describe 'GET /api/v1/brands' do
    let!(:brand) { brands(:coca_cola) }
    let!(:location) { locations(:downtown_office) }

    it 'returns all brands' do
      get '/api/v1/brands', params: { location_id: location.id },
                            headers: { Authorization: "Bearer #{access_token.token}" }

      json_response = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(json_response['brands']).to be_an(Array)
      expect(json_response['pagination']).to be_present
    end
  end
end
