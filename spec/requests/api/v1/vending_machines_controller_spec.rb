# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::VendingMachinesController, type: :request do
  describe 'GET /api/v1/vending_machines/nearby' do
    let!(:category) { create(:machine_category, name: 'Drinks') }
    let!(:vendor) { create(:vendor) }
    let!(:active_machine) do
      create(:vending_machine,
             vendor: vendor,
             category: category,
             status: 'active',
             location: 'POINT(-73.935242 40.730610)', # New York coordinates
             name: 'NYC Machine',
             location_name: 'Manhattan')
    end

    let!(:inactive_machine) do
      create(:vending_machine,
             vendor: vendor,
             category: category,
             status: 'inactive',
             location: 'POINT(-73.935242 40.730610)',
             name: 'Inactive NYC Machine',
             location_name: 'Manhattan')
    end

    let!(:far_machine) do
      create(:vending_machine,
             vendor: vendor,
             category: category,
             status: 'active',
             location: 'POINT(-118.243683 34.052235)', # Los Angeles coordinates
             name: 'LA Machine',
             location_name: 'Los Angeles')
    end

    context 'when there are machines nearby' do
      let(:params) do
        {
          latitude: 40.730610,   # New York coordinates
          longitude: -73.935242
        }
      end

      before { get nearby_api_v1_vending_machines_path, params: params }

      it 'returns success status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns correct message' do
        expect(json_response['message']).to eq('Machines found')
      end

      it 'returns only active machines within radius' do
        expect(json_response['machines'].length).to eq(1)
        expect(json_response['machines'].first['name']).to eq('NYC Machine')
      end

      it 'includes all required machine attributes' do
        machine = json_response['machines'].first
        expect(machine).to include(
          'id',
          'name',
          'location_name',
          'distance',
          'status',
          'category',
          'last_status'
        )
      end

      it 'returns distance in correct format' do
        expect(json_response['machines'].first['distance']).to be_a(Float)
      end
    end

    context 'when there are no machines nearby' do
      let(:params) do
        {
          latitude: 51.507351,   # London coordinates
          longitude: -0.127758
        }
      end

      before { get nearby_api_v1_vending_machines_path, params: params }

      it 'returns success status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns appropriate message' do
        expect(json_response['message']).to eq('No machines nearby')
      end

      it 'returns empty machines array' do
        expect(json_response['machines']).to be_empty
      end
    end

    context 'with invalid coordinates' do
      let(:params) do
        {
          latitude: 'invalid',
          longitude: 'invalid'
        }
      end

      before { get nearby_api_v1_vending_machines_path, params: params }

      it 'handles invalid coordinates gracefully' do
        expect(response).to have_http_status(:ok)
        expect(json_response['machines']).to be_empty
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
