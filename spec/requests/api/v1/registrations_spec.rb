# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User Registration', type: :request do
  let(:existing_user) { create(:user, email: 'user@example.com') }
  let(:valid_attributes) do
    {
      email: 'user@example.com',
      password: 'Password@!123',
      mobile_number: '+201234567890'
    }
  end

  let(:invalid_attributes) do
    {
      email: '',
      password: 'short'
    }
  end

  describe 'POST /api/v1/users/signup' do
    context 'with valid parameters' do
      it 'registers a new user and returns success' do
        post '/api/v1/users/signup', params: { user: valid_attributes }

        expect(response).to have_http_status(:created)
        expect(User.last.email).to eq(valid_attributes[:email])
      end
    end

    context 'with invalid parameters' do
      it 'does not register a user and returns errors' do
        post '/api/v1/users/signup', params: { user: invalid_attributes }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("can't be blank")
      end
    end

    context 'with valid but taken email' do
      before { existing_user }

      it 'returns an error for duplicate email' do
        post '/api/v1/users/signup', params: { user: valid_attributes }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['errors'].first['email']).to include('has already been taken')
      end
    end
  end
end
