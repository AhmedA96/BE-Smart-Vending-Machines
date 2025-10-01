# frozen_string_literal: true

module TapPayments
  class CreateCharge < BaseService
    class << self
      def call(source_type, payment, user)
        handle_customer_creation(user)

        body = prepare_params(source_type, payment, user)
        response = make_request(:post, tap_credentials[:create_charge_url], body)

        parsed_response = JSON.parse(response.body)
        status = parsed_response['status']
        code = extract_response_code(parsed_response)

        unless status == 'CAPTURED' && code == '000'
          payment.failed!
          payment.update!(message: parsed_response['response']['message'])
          raise StandardError, I18n.t('errors.card.failed_to_capture_charge')
        end

        payment.complete! if source_type == PAYMENT_OPERATION_TYPES[:order_payment]
        TapPayments::SaveChargeRecord.call(response, user.payment_customer.id, payment.id)
        response.success?
      end

      def extract_response_code(parsed_response)
        return nil if parsed_response['response'].blank?

        parsed_response['response']['code']
      end

      private

      def prepare_params(source_type, payment, user)
        reference_id = source_type == PAYMENT_OPERATION_TYPES[:order_payment] ? payment.order.number : payment.id

        {
          amount: payment.amount,
          currency: payment.currency,
          customer_initiated: true,
          threeDSecure: true,
          save_card: false,
          reference: { order: reference_id },
          receipt: { email: false, sms: false },
          customer: { id: user.payment_customer.payment_customer_number },
          source: { id: payment.token_id },
          post: { url: tap_credentials[:post_url] },
          redirect: { url: tap_credentials[:redirect_url] }
        }
      end
    end
  end
end
