# frozen_string_literal: true

module NotificationService
  class OrderNotifications
    def initialize(order)
      @order = order
      @user = order.user
      @machine = order.machine
    end

    def payment_initiated
      create_notification(
        type: Notification::TYPES[:order_payment],
        translation_key: 'notifications.order_payment',
        translation_params: { order_number: @order.number }
      )
    end

    def ready
      create_notification(
        type: Notification::TYPES[:order_ready],
        translation_key: 'notifications.order_ready',
        translation_params: {
          order_number: @order.number,
          machine_id: @machine.id
        },
        metadata: { order_id: @order.id, number: @order.number }
      )
    end

    def dispensed
      create_notification(
        type: Notification::TYPES[:order_dispensed],
        translation_key: 'notifications.order_dispensed',
        translation_params: {
          order_number: @order.number,
          machine_id: @machine.id
        },
        metadata: { order_id: @order.id, number: @order.number }
      )
    end

    private

    def create_notification(type:, translation_key:, translation_params:, metadata: {})
      Notifications::Create.new(
        user: @user,
        attributes: {
          type: type,
          translation_key: translation_key,
          translation_params: translation_params,
          notifiable: @order,
          metadata: metadata
        }
      ).call
    end
  end
end
