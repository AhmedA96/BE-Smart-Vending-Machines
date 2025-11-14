# frozen_string_literal: true

module PasswordReset
  class SendCode
    TOKEN_EXPIRY = 15.minutes

    def self.call(user)
      code = generate_reset_code

      user.update!(
        reset_password_token: code,
        reset_password_sent_at: Time.current
      )

      message = I18n.t('user.password_reset.otp_message', otp: code)

      if Rails.env.production?
        result = SmsGateway::Provider.send_sms(user.mobile_number, message)

        if result[:success]
          { success: true, code: code, provider: result[:provider] }
        else
          user.update!(reset_password_token: nil, reset_password_sent_at: nil)
          { success: false, error: result[:error] }
        end
      else
        { success: true, code: code, provider: 'development' }
      end
    end

    def self.generate_reset_code
      SecureRandom.random_number(10**6).to_s.rjust(6, '0')
    end

    def self.token_expired?(sent_at)
      return true if sent_at.nil?

      sent_at < TOKEN_EXPIRY.ago
    end
  end
end
