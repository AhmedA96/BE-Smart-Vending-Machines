# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::ProductsController, type: :request do
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: nil) }
  let(:product) { create(:product, status: 'Active') }
  let(:machine) { create(:machine) }
  let(:price_list) { create(:price_list) }

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
    let(:product) { create(:product) }

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
    let(:variant) { create(:variant, product: product) }
    let(:machine_item) { create(:machine_item, machine: machine, variant: variant) }

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
