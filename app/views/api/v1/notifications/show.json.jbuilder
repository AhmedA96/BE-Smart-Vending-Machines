# frozen_string_literal: true

json.message I18n.t('notifications.marked_as_read')
json.notification do
  json.partial! 'api/v1/notifications/notification', notification: @notification
end
