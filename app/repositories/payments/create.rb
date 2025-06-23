# frozen_string_literal: true

module Payments
  class Create
    def self.call(payment_data, order)
      amount = order.items_total

      return if amount <= 0

      create_payment(amount, payment_data, order)
    end

    def self.create_payment(amount, payment_data, order)
      attributes = {
        amount: amount,
        payment_method_id: payment_data[:payment_method_id],
        order: order,
        payment_type: :pay,
        card_id: payment_data[:card_id],
        token_id: payment_data[:token_id]
      }

      Payment.create!(attributes)
    end
  end
end
