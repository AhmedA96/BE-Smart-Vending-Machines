# rubocop:disable Naming/VariableNumber
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::LineItemsController, type: :request do
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: user.id) }
  let(:user) { users(:user_one) }
  let(:cart) { orders(:order_004) }
  let(:line_item) { line_items(:order_004_coke) }
  let(:variant) { variants(:coke_classic_12oz) }

  let(:headers) { { Authorization: "Bearer #{access_token.token}" } }

  before do
    allow(LineItems::Create).to receive(:call).and_return(line_item)
    allow(LineItems::Update).to receive(:call).and_return(cart)
    allow(LineItems::Destroy).to receive(:call).and_return(cart)
  end

  describe 'POST /api/v1/carts/:cart_id/line_items' do
    let(:params) do
      {
        line_item: { variant_id: variant.id, quantity: 2 }
      }
    end

    it 'creates line item successfully' do
      post "/api/v1/carts/#{cart.id}/line_items", params: params, headers: headers

      expect(response).to have_http_status(:created)
      expect(LineItems::Create).to have_received(:call)
    end
  end

  describe 'PUT /api/v1/carts/:cart_id/line_items/:id' do
    let(:params) do
      {
        line_item: { quantity: 5 }
      }
    end

    it 'updates line item successfully' do
      put "/api/v1/carts/#{cart.id}/line_items/#{line_item.id}", params: params, headers: headers

      expect(response).to have_http_status(:ok)
      expect(LineItems::Update).to have_received(:call)
    end
  end

  describe 'DELETE /api/v1/carts/:cart_id/line_items/:id' do
    it 'destroys line item successfully' do
      delete "/api/v1/carts/#{cart.id}/line_items/#{line_item.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(LineItems::Destroy).to have_received(:call)
    end
  end

  describe 'authorization' do
    let(:other_user) { users(:user_two) }
    let(:other_access_token) do
      create(:doorkeeper_access_token, application: application, resource_owner_id: other_user.id)
    end
    let(:other_headers) { { Authorization: "Bearer #{other_access_token.token}" } }

    it 'blocks access to other users cart' do
      params = { line_item: { variant_id: variant.id, quantity: 1 } }

      post "/api/v1/carts/#{cart.id}/line_items", params: params, headers: other_headers

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'cart validation' do
    let(:completed_order) { orders(:order_001) }

    it 'prevents modification of non-cart orders' do
      params = { line_item: { variant_id: variant.id, quantity: 1 } }

      post "/api/v1/carts/#{completed_order.id}/line_items", params: params, headers: headers

      expect(response).to have_http_status(:bad_request)
    end
  end
end

# rubocop:enable Naming/VariableNumber
