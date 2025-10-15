# frozen_string_literal: true

module NotificationService
  class OrderNotifications
    def initialize(order)
      @order = order
      @user = order.user
      @machine = order.machine
    end

    def payment_initiated
      base_call(
        type: Notification::TYPES[:order_payment],
        title: 'Payment Processing',
        body: "Your payment for order ##{@order.number} is being processed."
      )
    end

    def ready
      base_call(
        type: Notification::TYPES[:order_ready],
        title: 'Order Ready!',
        body: "Your order is ready at #{@machine.name}. Go to the machine to collect your items!",
        metadata: {
          order_id: @order.id,
          number: @order.number
        }
      )
    end

    def dispensed
      base_call(
        type: Notification::TYPES[:order_dispensed],
        title: 'Order Dispensed',
        body: "Your order is dispensed at #{@machine.name}.",
        metadata: {
          order_id: @order.id,
          number: @order.number
        }
      )
    end

    private

    def base_call(type:, title:, body:, metadata: {})
      Notifications::Create.new(
        user: @user,
        attributes: {
          type: type,
          title: title,
          body: body,
          notifiable: @order,
          metadata: metadata
        }
      ).call
    end
  end
end
