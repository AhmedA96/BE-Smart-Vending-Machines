# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::VariantsController, type: :request do
  describe 'GET /api/v1/variants' do
    let(:product) { create(:product) }
    let!(:variants) { create_list(:variant, 2, product: product) }

    it 'returns a list of variants for a product' do
      get '/api/v1/variants', params: { product_id: product.id }

      json_response = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json_response['variants']).to be_present
    end
  end

  describe 'GET /api/v1/variants/:id' do
    let(:product) { create(:product) }
    let(:variant) { create(:variant, product: product) }

    it 'returns variant by :id' do
      get "/api/v1/variants/#{variant.id}"

      json_response = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json_response['variant']).to be_present
      expect(json_response['variant']['id']).to eq(variant.id)
    end
  end
end
