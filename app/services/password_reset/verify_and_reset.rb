# frozen_string_literal: true

module PasswordReset
  class VerifyAndReset
    def self.call(user:, code:, new_password:, password_confirmation:)
      if PasswordReset::SendCode.token_expired?(user.reset_password_sent_at)
        return {
          success: false,
          error: I18n.t('user.password_reset.errors.expired_code')
        }
      end

      # Verify code matches
      unless user.reset_password_token == code
        return {
          success: false,
          error: I18n.t('user.password_reset.errors.invalid_code')
        }
      end

      # Verify password confirmation
      unless new_password == password_confirmation
        return {
          success: false,
          error: I18n.t('user.password_reset.errors.passwords_dont_match')
        }
      end

      if user.update(
        password: new_password,
        password_confirmation: password_confirmation,
        reset_password_token: nil,
        reset_password_sent_at: nil
      )
        { success: true }
      else
        {
          success: false,
          error: user.errors.full_messages.first
        }
      end
    end
  end
end
