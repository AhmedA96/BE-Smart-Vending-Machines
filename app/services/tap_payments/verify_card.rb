# frozen_string_literal: true

module TapPayments
  class VerifyCard < BaseService
    class << self
      def call(card_id, customer_number)
        customer = PaymentCustomer.find_by(customer_number: customer_number)
        return false unless customer

        response = make_request(
          :get,
          "#{tap_credentials[:card_url]}/#{customer_number}",
          customer: customer
        )

        return false unless response.success?

        cards = response.parsed_response['data']
        card = cards.find { |c| c['id'] == card_id }

        !card.nil?
      end
    end
  end
end
