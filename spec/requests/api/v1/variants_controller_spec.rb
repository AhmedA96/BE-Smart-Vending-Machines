# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::VariantsController, type: :request do
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: nil) }
  let(:product) { products(:coke_classic) }

  describe 'GET /api/v1/variants' do
    it 'returns a list of variants for a product' do
      get '/api/v1/variants',
          headers: { Authorization: "Bearer #{access_token.token}" },
          params: { product_id: product.id }

      json_response = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json_response['variants']).to be_present
    end
  end

  describe 'GET /api/v1/variants/:id' do
    let(:variant) { variants(:coke_classic_12oz) }

    it 'returns variant by :id' do
      get "/api/v1/variants/#{variant.id}",
          headers: { Authorization: "Bearer #{access_token.token}" }

      json_response = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json_response['variant']).to be_present
      expect(json_response['variant']['id']).to eq(variant.id)
    end
  end
end
