# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::MachinesController, type: :request do
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: nil) }

  describe 'GET /api/v1/machines/nearby' do
    let!(:machine) { create(:machine, coordinates: 'POINT(-74.0060 40.7128)', status: 'Active') }
    let(:params) { { latitude: 40.7128, longitude: -74.0060, radius_in_meters: 1000 } }

    it 'returns nearby machines' do
      get '/api/v1/machines/nearby', headers: { Authorization: "Bearer #{access_token.token}" }, params: params

      json_response = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json_response['machines']).to be_an(Array)
      expect(json_response['machines'].first).to include('distance')
      expect(json_response['pagination']).to be_present
    end
  end

  describe 'GET /api/v1/machines/:id' do
    let!(:machine) { create(:machine) }

    it 'returns machine by :id' do
      get "/api/v1/machines/#{machine.id}", headers: { Authorization: "Bearer #{access_token.token}" }

      json_response = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json_response['machine']).to be_present
    end
  end
end
