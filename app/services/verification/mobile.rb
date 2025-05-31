# frozen_string_literal: true

module Verification
  class Mobile
    def self.send_code(mobile_number, user)
      verification_code = generate_verification_code
      message = I18n.t('verification.mobile.otp_message', otp: verification_code)

      SmsGateway::Synapse.send_sms(mobile_number, message)

      MobileVerifications::Create.call(mobile_number, verification_code, user)
      true
    end

    def self.generate_verification_code
      SecureRandom.random_number(10**6).to_s.rjust(6, '0')
    end
  end
end
