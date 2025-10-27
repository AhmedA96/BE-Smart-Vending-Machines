# frozen_string_literal: true

module TapPayments
  class CreateCardCharge < BaseService
    class << self
      def call(source_type, payment, token_id, card_id, user)
        handle_customer_creation(user)

        body = build_charge_params(source_type, payment, token_id, card_id, user)
        make_request(:post, tap_credentials[:create_charge_url], body)
      end

      private

      def build_charge_params(source_type, payment, token_id, card_id, user)
        card = user.payment_customer.payment_cards.find(card_id)
        currency = payment.currency

        base_params = {
          amount: payment.amount,
          currency: currency,
          customer_initiated: false,
          threeDSecure: true,
          save_card: false,
          customer: { id: user.payment_customer.payment_customer_number },
          source: { id: token_id },
          post: { url: tap_credentials[:post_url] },
          redirect: { url: tap_credentials[:redirect_url] },
          payment_agreement: { id: card.payment_agreement_id }
        }

        case source_type
        when PAYMENT_OPERATION_TYPES[:order_payment]
          base_params.merge(order_specific_params(payment))
        when PAYMENT_OPERATION_TYPES[:wallet_refill]
          base_params.merge(wallet_specific_params(payment))
        else
          raise FailedRequestError, "Unsupported source_type: #{source_type}"
        end
      end

      def order_specific_params(payment)
        {
          description: 'VNDG Payment',
          reference: { order: payment.order.number },
          receipt: { email: false, sms: false }
        }
      end

      def wallet_specific_params(payment)
        {
          description: 'VNDG Payment',
          reference: {
            source_type: 'Wallet Refill',
            source_id: payment.id
          },
          receipt: { email: true, sms: true }
        }
      end
    end
  end
end
