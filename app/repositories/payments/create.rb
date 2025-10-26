# frozen_string_literal: true

module Payments
  class Create
    def self.call(payment_data, order)
      if order.payments.completed.exists?
        raise FailedRequestError,
              'This order has already been paid and cannot accept new payments.'
      end

      amount = order.items_total
      return if amount <= 0

      payment = create_payment(amount, payment_data, order)

      transition_order_to_payment(order)

      payment
    end

    def self.create_payment(amount, payment_data, order)
      attributes = {
        amount: amount,
        payment_method_id: payment_data[:payment_method_id],
        order: order,
        card_id: payment_data[:card_id],
        token_id: payment_data[:token_id]
      }
      Payment.create!(attributes)
    end

    def self.transition_order_to_payment(order)
      if order.may_start_payment?
        order.start_payment!
      else
        Rails.logger.info("Order ##{order.id} is in '#{order.status}' state, skipping transition")
      end
    end
  end
end
