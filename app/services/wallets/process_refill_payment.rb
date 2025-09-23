# frozen_string_literal: true

module Wallets
  class ProcessRefillPayment
    class << self
      def call(wallet_refill, user)
        process_refill_payment(wallet_refill, user)
      end

      private

      def process_refill_payment(wallet_refill, user)
        return fail_refill(wallet_refill, 'User authentication required') if user.blank?

        method_name = wallet_refill.payment_method.name.downcase

        case method_name
        when 'credit', 'credit_card'
          process_credit_refill(wallet_refill, user)
        when 'apple_pay', 'google_pay', 'digital_wallet'
          process_digital_wallet_refill(wallet_refill, user)
        else
          fail_refill(wallet_refill, "Payment method '#{wallet_refill.payment_method.name}' is not supported")
        end
      rescue StandardError => e
        fail_refill(wallet_refill, e.message)
      end

      def process_credit_refill(wallet_refill, user)
        return fail_refill(wallet_refill, 'No card selected') if wallet_refill.card_id.blank?

        Wallets::CreateCreditCharge.call(wallet_refill, user)
        true
      rescue StandardError => e
        fail_refill(wallet_refill, e.message)
      end

      def process_digital_wallet_refill(wallet_refill, user)
        TapPayments::CreateChargeApi.call('Wallet Refill', wallet_refill, user)
        true
      rescue StandardError => e
        fail_refill(wallet_refill, e.message)
      end

      def fail_refill(wallet_refill, message)
        wallet_refill.failed!
        wallet_refill.update!(message: message) if wallet_refill.respond_to?(:message)
        false
      end
    end
  end
end
