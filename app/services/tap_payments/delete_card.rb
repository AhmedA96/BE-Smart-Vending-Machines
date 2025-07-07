# frozen_string_literal: true

module TapPayments
  class DeleteCard < BaseService
    class << self
      def call(card_id, customer_number)
        customer = PaymentCustomer.find_by(payment_customer_number: customer_number)
        return false unless customer

        response = make_request(
          :delete,
          "#{tap_credentials[:card_url]}/#{customer_number}/#{card_id}"
        )

        body = JSON.parse(response.body)

        return true if response.success? && body['deleted']
        return true if response.code == 404 # Card already deleted

        raise StandardError, I18n.t('errors.card.failed_to_delete')
      end
    end
  end
end
