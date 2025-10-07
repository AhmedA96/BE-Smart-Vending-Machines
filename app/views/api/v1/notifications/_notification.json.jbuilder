# frozen_string_literal: true

json.extract! notification, :id, :notification_type, :title, :body, :read, :read_at, :metadata, :created_at

if notification.notifiable.present?
  json.notifiable do
    json.type notification.notifiable_type
    json.id notification.notifiable_id

    json.status notification.notifiable.status if notification.notifiable.is_a?(Order)
  end
else
  json.notifiable nil
end
