# frozen_string_literal: true

module Orders
  class ProcessPayment
    class << self
      def call(order, user)
        process_order_payments(order, user)
      end

      def process_order_payments(order, user)
        payments = order.payments.pending

        payment_results = payments.map do |payment|
          process_single_payment(payment, user)
        end

        handle_payment_response(order, payments, payment_results)
      end

      private

      def process_single_payment(payment, user)
        if user.blank?
          payment.failed!
          payment.update!(message: 'User authentication required for payment processing')
          return false
        end

        method_name = payment.payment_method.name.downcase

        case method_name
        when 'credit_card'
          process_credit_payment(payment, user)
        when 'apple_pay', 'google_pay', 'digital_wallet'
          process_digital_wallet_payment(payment, user)
        else
          payment.failed!
          payment.update!(message: "Payment method '#{payment.payment_method.name}' is not supported")
          false
        end
      end

      def process_credit_payment(payment, user)
        if payment.card_id.present?
          TapPayments::CreateCardCharge.call(payment, payment.token_id, payment.card_id, user)
        elsif payment.token_id.present?
          TapPayments::CreateCharge.call(payment, user)
        else
          payment.failed!
          payment.update!(message: 'No payment method provided')
          false
        end
      end

      def process_digital_wallet_payment(payment, user)
        TapPayments::CreateCharge.call(payment, user)
      end

      def handle_payment_response(order, payments, _payment_results)
        payments.reload

        completed_payments = payments.completed
        total_paid = completed_payments.sum(:amount)

        total_paid >= order.items_total && completed_payments.any?
      end
    end
  end
end
