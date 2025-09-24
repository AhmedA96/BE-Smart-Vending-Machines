# frozen_string_literal: true

module Orders
  class ProcessPayment
    class << self
      def call(order, user)
        process_order_payments(order, user)
      end

      private

      def process_order_payments(order, user)
        payments = order.payments.pending

        return false unless validate_payment_total(payments, order)

        payment_results = payments.map do |payment|
          process_single_payment(payment, order, user)
        end

        handle_payment_response(order, payments, payment_results)
      end

      def validate_payment_total(payments, order)
        total_pending = payments.sum(:amount)
        return true if total_pending <= order.items_total

        payments.each do |payment|
          payment.failed!
          payment.update!(message: 'Total pending payments exceed order total')
        end
        false
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

        Orders::CreateCreditCharge.call('Order Payment', order, user)
        true
      rescue StandardError => e
        fail_payment(payment, e.message)
      end

      def process_digital_wallet_payment(payment, user)
        TapPayments::CreateCharge.call(payment, user)
        true
      rescue StandardError => e
        fail_payment(payment, e.message)
      end

      def fail_payment(payment, message)
        payment.failed!
        payment.update!(message: message)
        false
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
