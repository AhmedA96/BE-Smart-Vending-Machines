# frozen_string_literal: true

module TapPayments
  class BaseService
    class << self
      private

      def make_request(method, url, body = nil)
        options = {
          headers: default_headers
        }
        options[:body] = body.to_json if body

        response = HTTParty.send(method, url, options)
        log_request(method, url, body, response) if method == :post
        response
      end

      def default_headers
        {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{tap_credentials[:secret_key]}",
          'Accept' => 'application/json'
        }
      end

      def log_request(method, _url, body, response)
        Rails.logger.info("TapPayments::#{name}.#{method} request: (#{body&.to_json}) - response: #{response}")
      end

      def handle_customer_creation(user)
        return if user.payment_customer.present?

        customer_result = TapPayments::CreateCustomer.call(user)
        customer_result unless customer_result.code == 200
      end

      def tap_credentials
        Rails.application.credentials.tap_payment
      end
    end
  end
end
