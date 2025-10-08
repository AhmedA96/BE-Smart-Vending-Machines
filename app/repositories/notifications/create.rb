# frozen_string_literal: true

module Notifications
  class Create
    def initialize(user:, attributes:)
      @user = user
      @attributes = attributes.symbolize_keys
    end

    def call
      validate_type!

      Notification.create!(
        user: @user,
        notifiable: @attributes[:notifiable],
        notification_type: @attributes[:type],
        title: @attributes[:title],
        body: @attributes[:body],
        metadata: @attributes[:metadata] || {}
      )
    end

    private

    def validate_type!
      type = @attributes[:type]
      return if Notification::TYPES.value?(type)

      raise ArgumentError, "Invalid notification type: #{type.inspect}"
    end
  end
end
