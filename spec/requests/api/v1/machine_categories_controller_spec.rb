# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::MachineCategoriesController, type: :request do
  describe 'GET /api/v1/machine_categories' do
    let!(:machine_category) { create(:machine_category) }

    it 'returns all machine categories' do
      get '/api/v1/machine_categories'

      json_response = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json_response['machine_categories']).to be_an(Array)
      expect(json_response['pagination']).to be_present
    end
  end

  describe 'GET /api/v1/machine_categories/:id' do
    let!(:machine_category) { create(:machine_category) }

    it 'returns machine category by :id' do
      get "/api/v1/machine_categories/#{machine_category.id}"

      json_response = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json_response['machine_category']).to be_present
    end
  end
end
