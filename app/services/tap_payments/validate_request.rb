# frozen_string_literal: true

require 'openssl'
require 'money'

module TapPayments
  class ValidateRequest < BaseService
    class << self
      def call(params, headers)
        validate_request(params, headers)
      end

      private

      def validate_request(params, headers)
        validate_params!(params)

        posted_hash = headers['hashstring']
        computed_hash = compute_hash_string(params, tap_credentials[:secret_key])

        raise StandardError, I18n.t('errors.payment.invalid_hash') unless computed_hash == posted_hash

        true
      end

      def validate_params!(params)
        required_params = [
          params[:id],
          params[:amount],
          params[:currency],
          params.dig(:reference, :gateway),
          params.dig(:reference, :payment),
          params[:status],
          params.dig(:transaction, :created)
        ]

        raise StandardError, I18n.t('errors.payment.missing_parameters') if required_params.any?(&:blank?)
      end

      def compute_hash_string(params, secret_key)
        amount = params[:amount].is_a?(String) ? params[:amount].to_f : params[:amount]
        rounded_amount = format_amount(amount, params[:currency])

        to_be_hashed_string = "x_id#{params[:id]}" \
                              "x_amount#{rounded_amount}" \
                              "x_currency#{params[:currency]}" \
                              "x_gateway_reference#{params.dig(:reference, :gateway)}" \
                              "x_payment_reference#{params.dig(:reference, :payment)}" \
                              "x_status#{params[:status]}" \
                              "x_created#{params.dig(:transaction, :created)}"

        OpenSSL::HMAC.hexdigest('sha256', secret_key, to_be_hashed_string)
      end

      def format_amount(amount, currency)
        money = Money.from_amount(amount, currency)
        money.format(symbol: false, decimal_mark: '.', thousands_separator: '')
      end
    end
  end
end
