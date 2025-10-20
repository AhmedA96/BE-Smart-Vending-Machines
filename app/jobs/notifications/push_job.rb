# frozen_string_literal: true

module Notifications
  class PushJob < ApplicationJob
    queue_as :notifications

    def perform(notification_id)
      notification = Notification.find(notification_id)
      user = notification.user

      return if user.devices.blank?

      firebase = Firebase::PushService.new

      user.devices.find_each do |device|
        firebase.send_notification(
          device_token: device.token,
          title: notification.title,
          body: notification.body,
          data: notification.metadata.merge(notification_id: notification.id)
        )
      end
    end
  end
end
