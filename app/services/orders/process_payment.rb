# frozen_string_literal: true

module Orders
  class ProcessPayment
    class << self
      def call(order, user)
        process_order_payment(order, user)
      end

      private

      def process_order_payment(order, user)
        payment = order.payments.last_pending
        return false if payment.blank?

        return false unless validate_payment_total(payment, order)

        result = process_single_payment(payment, order, user)
        handle_payment_response(order, payment, result)
      end

      def validate_payment_total(payment, order)
        if payment.amount > order.items_total
          payment.failed!
          payment.update!(message: 'Payment amount exceeds order total')
          return false
        end
        true
      end

      def process_single_payment(payment, order, user)
        return fail_payment(payment, 'User authentication required') if user.blank?

        method_name = payment.payment_method.name.downcase

        case method_name
        when 'credit', 'credit_card'
          process_credit_payment(payment, order, user)
        when 'apple_pay', 'google_pay', 'digital_wallet'
          process_digital_wallet_payment(payment, user)
        else
          fail_payment(payment, "Payment method '#{payment.payment_method.name}' is not supported")
        end
      rescue StandardError => e
        fail_payment(payment, e.message)
      end

      def process_credit_payment(payment, order, user)
        return fail_payment(payment, 'No card selected') if payment.card_id.blank?

        Orders::CreateCreditCharge.call(order, user)
        true
      rescue StandardError => e
        fail_payment(payment, e.message)
      end

      def process_digital_wallet_payment(payment, user)
        TapPayments::CreateCharge.call('Order Payment', payment, user)
        true
      rescue StandardError => e
        fail_payment(payment, e.message)
      end

      def fail_payment(payment, message)
        payment.failed!
        payment.update!(message: message)
        false
      end

      def handle_payment_response(order, _payment, _result)
        completed_payments = order.payments.completed
        total_paid = completed_payments.sum(:amount)

        total_paid >= order.items_total && completed_payments.any?
      end
    end
  end
end
