# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::PaymentMethodsController, type: :request do
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: nil) }
  let(:machine) { machines(:machine_001) } # rubocop:disable Naming/VariableNumber
  let(:payment_method) { payment_methods(:credit_card) }

  describe 'GET /api/v1/payment_methods' do
    it 'returns all active payment methods for machines' do
      get '/api/v1/payment_methods', headers: { Authorization: "Bearer #{access_token.token}" }
      json_response = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(json_response['payment_methods']).to be_an(Array)
      expect(json_response['pagination']).to be_present
    end
  end

  describe 'GET /api/v1/payment_methods/:id' do
    it 'returns a specific payment method' do
      get "/api/v1/payment_methods/#{payment_method.id}", headers: { Authorization: "Bearer #{access_token.token}" }
      json_response = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(json_response['payment_method']).to be_present
    end

    it 'returns 404 when payment method not found' do
      get '/api/v1/payment_methods/999999', headers: { Authorization: "Bearer #{access_token.token}" }

      expect(response).to have_http_status(:not_found)
    end
  end
end
