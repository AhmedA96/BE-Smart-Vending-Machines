# frozen_string_literal: true

module TapPayments
  class CreateCustomer < BaseService
    class << self
      def call(user)
        body = customer_data(user)
        result = make_request(:post, tap_credentials[:create_customer_url], body)

        return result unless result.code == 200

        PaymentCustomer.create!(user:, payment_customer_number: result['id'])
        result
      end

      private

      def customer_data(user)
        {
          first_name: user.name,
          phone: {
            number: user.mobile_number
          }
        }
      end
    end
  end
end
