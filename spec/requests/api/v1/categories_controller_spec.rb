# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::CategoriesController, type: :request do
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: nil) }

  describe 'GET /api/v1/categories' do
    let!(:category) { create(:category) }

    it 'returns all categories' do
      get '/api/v1/categories', headers: { Authorization: "Bearer #{access_token.token}" }

      json_response = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json_response['categories']).to be_an(Array)
      expect(json_response['pagination']).to be_present
    end
  end

  describe 'GET /api/v1/mcategories/:id' do
    let!(:category) { create(:category) }

    it 'returns category by :id' do
      get "/api/v1/categories/#{category.id}", headers: { Authorization: "Bearer #{access_token.token}" }

      json_response = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json_response['category']).to be_present
    end
  end
end
