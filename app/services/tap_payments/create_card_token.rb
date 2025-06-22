# frozen_string_literal: true

module TapPayments
  class CreateCardToken < BaseService
    class << self
      def call(card_id, customer_id)
        body = prepare_params(card_id, customer_id)
        make_request(:post, tap_credentials[:create_card_token_url], body)
      end

      private

      def prepare_params(card_id, customer_id)
        {
          saved_card: {
            card_id:,
            customer_id:
          }
        }
      end
    end
  end
end
