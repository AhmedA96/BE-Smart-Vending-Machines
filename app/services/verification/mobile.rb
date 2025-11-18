# frozen_string_literal: true

module Verification
  class Mobile
    class << self
      def send_code(mobile_number, user, provider: nil)
        verification_code = generate_verification_code
        message = I18n.t('verification.mobile.otp_message', otp: verification_code)

        result = SmsGateway::Provider.send_sms(mobile_number, message, provider)

        if result[:success]
          MobileVerifications::Create.call(mobile_number, verification_code, user)
          { success: true, code: verification_code, provider: result[:provider] }
        else
          Rails.logger.error("Failed to send SMS via #{result[:provider]}: #{result[:error]}")
          { success: false, error: result[:error], provider: result[:provider] }
        end
      end

      def generate_verification_code
        SecureRandom.random_number(10**6).to_s.rjust(6, '0')
      end
    end
  end
end
