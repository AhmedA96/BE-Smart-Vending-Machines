# frozen_string_literal: true

module TapPayments
  class CreateCardCharge < BaseService
    class << self
      def call(payment, token_id, card_id, user)
        handle_customer_creation(user)

        body = prepare_order_params(payment, token_id, card_id, user)
        make_request(:post, tap_credentials[:create_charge_url], body)
      end

      private

      def prepare_order_params(payment, token_id, card_id, user)
        card = user.payment_customer.payment_cards.find(card_id)
        order = payment.order
        currency = payment.currency
        {
          amount: payment.amount,
          currency:,
          customer_initiated: false,
          threeDSecure: true,
          save_card: false,
          reference: { order: order.number },
          receipt: { email: false, sms: false },
          customer: { id: user.payment_customer.payment_customer_number },
          source: { id: token_id },
          post: { url: tap_credentials[:post_url] },
          redirect: { url: tap_credentials[:redirect_url] },
          payment_agreement: { id: card.payment_agreement_id }
        }
      end
    end
  end
end
