# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::ProductsController, type: :request do
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: nil) }
  let(:product) { products(:coke_classic) }
  let(:machine) { machines(:machine_001) } # rubocop:disable Naming/VariableNumber
  let(:price_list) { price_lists(:standard_pricing) }

  before do
    allow_any_instance_of(Products::PriceListFindable).to receive(:find_machine).and_return(machine)
    allow_any_instance_of(Products::PriceListFindable).to receive(:machine_price_list).and_return(price_list)
  end

  describe 'GET /api/v1/products' do
    it 'returns a successful response' do
      get '/api/v1/products', headers: { Authorization: "Bearer #{access_token.token}" }
      expect(response).to be_successful
    end
  end

  describe 'GET /api/v1/products/:id' do
    let(:product) { products(:coke_classic) }

    it 'returns a successful response' do
      get "/api/v1/products/#{product.id}", headers: { Authorization: "Bearer #{access_token.token}" }
      expect(response).to be_successful
    end

    it 'returns the requested product' do
      get "/api/v1/products/#{product.id}", headers: { Authorization: "Bearer #{access_token.token}" }

      json_response = response.parsed_body
      expect(json_response['product']['id']).to eq(product.id)
    end
  end

  describe 'GET /api/v1/products/machine_products' do
    let(:variant) { variants(:coke_classic_12oz) }
    let(:machine_item) { machine_items(:machine_001_coke) }

    before do
      machine_item
    end

    it 'returns a successful response' do
      get '/api/v1/products/machine_products', headers: { Authorization: "Bearer #{access_token.token}" },
                                               params: { machine_id: machine.id }
      expect(response).to be_successful
    end

    it 'returns products for the specified machine' do
      get '/api/v1/products/machine_products', headers: { Authorization: "Bearer #{access_token.token}" },
                                               params: { machine_id: machine.id }

      json_response = response.parsed_body
      expect(json_response['products']).to be_present
      expect(json_response['products'].first['id']).to eq(product.id)
    end
  end
end
