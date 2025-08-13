# rubocop:disable Naming/VariableNumber
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::OrdersController, type: :request do
  let(:user) { users(:user_one) }
  let(:order) { orders(:order_001) }
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: user.id) }

  describe 'GET /api/v1/orders' do
    let!(:user_orders) { [orders(:order_001), orders(:order_003)] }

    before do
      allow(user).to receive(:orders).and_return(user_orders)
    end

    it 'returns all user orders' do
      get '/api/v1/orders', headers: { Authorization: "Bearer #{access_token.token}" }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /api/v1/orders/:id' do
    let!(:order) { orders(:order_001) }

    it 'returns the specific order' do
      get "/api/v1/orders/#{order.id}", headers: { Authorization: "Bearer #{access_token.token}" }

      expect(response).to have_http_status(:ok)
    end

    context 'when order is not found' do
      it 'returns not found status' do
        get '/api/v1/orders/999', headers: { Authorization: "Bearer #{access_token.token}" }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/orders/:id/reorder' do
    let!(:completed_order) { orders(:order_001) } # Make sure this is a completed order

    it 'successfully reorders items and creates a new cart' do
      expect do
        post "/api/v1/orders/#{completed_order.id}/reorder",
             headers: { Authorization: "Bearer #{access_token.token}" }
      end.to change(Order, :count).by(1)

      expect(response).to have_http_status(:created)

      response_data = response.parsed_body
      expect(response_data['success']).to be true
      expect(response_data['message']).to include('Successfully created new cart')
      expect(response_data['new_cart']).to be_present
      expect(response_data['original_order']['id']).to eq(completed_order.id)
    end

    context 'when machine is not active' do
      before do
        completed_order.machine.update!(status: 'Inactive')
      end

      it 'returns an error' do
        post "/api/v1/orders/#{completed_order.id}/reorder",
             headers: { Authorization: "Bearer #{access_token.token}" }

        expect(response).to have_http_status(:bad_request)

        response_data = response.parsed_body
        expect(response_data['error']['message']).to eq('Machine not available')
      end
    end

    context 'when order is not found' do
      it 'returns not found status' do
        post '/api/v1/orders/999/reorder',
             headers: { Authorization: "Bearer #{access_token.token}" }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

# rubocop:enable Naming/VariableNumber
