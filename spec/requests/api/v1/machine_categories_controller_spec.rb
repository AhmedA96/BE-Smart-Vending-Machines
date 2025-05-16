# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::MachineCategoriesController, type: :request do
  let!(:machine_category) { create(:machine_category) }
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: nil) }

  describe 'GET /api/v1/machine_categories' do
    it 'returns all machine categories' do
      get '/api/v1/machine_categories', headers: { Authorization: "Bearer #{access_token.token}" }

      json_response = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json_response['machine_categories']).to be_an(Array)
      expect(json_response['pagination']).to be_present
    end
  end

  describe 'GET /api/v1/machine_categories/:id' do
    it 'returns machine category by :id' do
      get "/api/v1/machine_categories/#{machine_category.id}",
          headers: { Authorization: "Bearer #{access_token.token}" }

      json_response = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json_response['machine_category']).to be_present
    end
  end
end
