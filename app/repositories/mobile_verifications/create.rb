# frozen_string_literal: true

module MobileVerifications
  class Create
    def self.call(mobile_number, verification_code, user)
      MobileVerification.create!(
        mobile_number:,
        code: verification_code,
        user:
      )
    end
  end
end
