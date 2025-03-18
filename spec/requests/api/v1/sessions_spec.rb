# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User Sessions', type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'Password@123') }

  describe 'POST /api/v1/users/login' do
    context 'with valid credentials' do
      it 'returns 201 Created' do
        post '/api/v1/users/login', params: { email: user.email, password: 'Password@123' }
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid password' do
      it 'returns 422 Unprocessable Entity' do
        post '/api/v1/users/login', params: { email: user.email, password: 'wrongpassword' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Invalid email or password')
      end
    end

    context 'with non-existent email' do
      it 'returns 422 Unprocessable Entity' do
        post '/api/v1/users/login', params: { email: 'unknown@example.com', password: 'password123' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Invalid email or password')
      end
    end
  end

  describe 'DELETE /api/v1/users/logout' do
    before do
      post '/api/v1/users/login', params: { email: user.email, password: 'Password@123' }
    end

    context 'when user is logged in' do
      it 'returns 204 No Content' do
        delete '/api/v1/users/logout'
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when no user is logged in' do
      it 'still returns 204 No Content' do
        delete '/api/v1/users/logout'
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
