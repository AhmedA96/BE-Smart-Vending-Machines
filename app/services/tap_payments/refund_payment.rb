# frozen_string_literal: true

module TapPayments
  class RefundPayment < BaseService
    class << self
      def call(payment, amount)
        charge = payment.payment_transactions.last
        raise StandardError, I18n.t('errors.payment.no_charge_found') unless charge

        body = prepare_refund_params(payment, charge, amount)
        response = make_request(:post, tap_credentials[:refund_url], body)

        parsed_response = JSON.parse(response.body)

        unless response.success? && parsed_response['status'] == 'REFUNDED'
          raise StandardError, parsed_response['message'] || I18n.t('errors.payment.refund_failed')
        end

        true
      end

      private

      def prepare_refund_params(payment, charge, amount)
        {
          charge_id: charge.charge_id,
          amount: amount,
          currency: payment.currency,
          reason: 'requested_by_customer',
          reference: {
            order: payment.order.number
          },
          metadata: {}
        }
      end
    end
  end
end
