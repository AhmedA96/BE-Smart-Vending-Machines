# frozen_string_literal: true

json.notifications @notifications do |notification|
  json.partial! 'api/v1/notifications/notification', notification: notification
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @notifications
end
