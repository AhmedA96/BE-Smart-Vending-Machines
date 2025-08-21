# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::UserFavoritesController, type: :request do
  let(:user) { users(:user_one) }
  let(:product) { products(:coke_classic) }
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: user.id) }

  describe 'POST /api/v1/users/favorites/:product_id' do
    it 'creates a new favorite' do
      expect do
        post "/api/v1/users/favorites/#{product.id}",
             headers: { Authorization: "Bearer #{access_token.token}" }
      end.to change(UserFavorite, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body['message']).to eq('Item added to favorites')
      expect(body['favorite']['product_id']).to eq(product.id)
    end

    it 'returns errors if duplicate favorite' do
      UserFavorite.create!(user: user, product: product)

      post "/api/v1/users/favorites/#{product.id}",
           headers: { Authorization: "Bearer #{access_token.token}" }

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.parsed_body
      expect(body['errors']).to include('User has already been taken')
    end
  end

  describe 'DELETE /api/v1/users/favorites/:product_id' do
    it 'removes an existing favorite' do
      UserFavorite.create!(user: user, product: product)

      expect do
        delete "/api/v1/users/favorites/#{product.id}",
               headers: { Authorization: "Bearer #{access_token.token}" }
      end.to change(UserFavorite, :count).by(-1)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['message']).to eq('Item removed from favorites')
    end
  end
end
