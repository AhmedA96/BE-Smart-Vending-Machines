# frozen_string_literal: true

module Api
  module V1
    class TapWebhookController < ApplicationController
      skip_before_action :doorkeeper_authorize!
      before_action :validate_webhook

      def create
        if TapPayments::SavePaymentResult.call(params)
          head :ok
        else
          head :unprocessable_content
        end
      end

      private

      def validate_webhook
        TapPayments::ValidateRequest.call(params, request.headers)
      rescue StandardError => e
        Rails.logger.error "Tap webhook validation failed: #{e.message}"
        head :unauthorized
      end
    end
  end
end
