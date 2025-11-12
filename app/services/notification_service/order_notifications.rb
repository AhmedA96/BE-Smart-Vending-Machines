# frozen_string_literal: true

module NotificationService
  class OrderNotifications
    def initialize(order)
      @order = order
      @user = order.user
      @machine = order.machine
    end

    def payment_initiated
      localized_for_user(@user) do
        base_call(
          type: Notification::TYPES[:order_payment],
          title: I18n.t('notifications.order_payment.title', order_number: @order.number),
          body: I18n.t('notifications.order_payment.body', order_number: @order.number, machine_name: @machine.name)
        )
      end
    end

    def ready
      localized_for_user(@user) do
        base_call(
          type: Notification::TYPES[:order_ready],
          title: I18n.t('notifications.order_ready.title'),
          body: I18n.t('notifications.order_ready.body', machine_name: @machine.name),
          metadata: {
            order_id: @order.id,
            number: @order.number
          }
        )
      end
    end

    def dispensed
      localized_for_user(@user) do
        base_call(
          type: Notification::TYPES[:order_dispensed],
          title: I18n.t('notifications.order_dispensed.title'),
          body: I18n.t('notifications.order_dispensed.body', machine_name: @machine.name),
          metadata: {
            order_id: @order.id,
            number: @order.number
          }
        )
      end
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

    def localized_for_user(user, &)
      locale = user.locale.presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
      I18n.with_locale(locale, &)
    end
  end
end
