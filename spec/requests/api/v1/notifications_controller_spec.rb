# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::NotificationsController, type: :request do
  fixtures :users, :notifications

  let(:user) { users(:user_one) }
  let(:notification) { notifications(:order_payment) }
  let(:application) { create(:oauth_application) }
  let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: user.id) }

  describe 'GET /api/v1/notifications' do
    it 'returns a list of user notifications' do
      get '/api/v1/notifications', headers: { Authorization: "Bearer #{access_token.token}" }

      expect(response).to have_http_status(:ok)

      json_response = response.parsed_body
      expect(json_response).not_to be_empty
    end
  end

  describe 'PUT /api/v1/notifications/:id/mark_as_read' do
    it 'marks the notification as read' do
      put "/api/v1/notifications/#{notification.id}/mark_as_read",
          headers: { Authorization: "Bearer #{access_token.token}" }

      expect(response).to have_http_status(:ok)
      expect(notification.reload.read).to eq(true)
      expect(notification.read_at).not_to be_nil
    end
  end

  describe 'PUT /api/v1/notifications/mark_all_as_read' do
    it 'marks all notifications as read for the current user' do
      put '/api/v1/notifications/mark_all_as_read', headers: { Authorization: "Bearer #{access_token.token}" }

      expect(response).to have_http_status(:ok)

      json_response = response.parsed_body
      expect(json_response['message']).to eq(I18n.t('notifications.mark_all_as_read'))
      expect(user.notifications.unread.count).to eq(0)
    end
  end

  describe 'DELETE /api/v1/notifications/:id' do
    it 'deletes the notification' do
      expect do
        delete "/api/v1/notifications/#{notification.id}", headers: { Authorization: "Bearer #{access_token.token}" }
      end.to change(Notification, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
