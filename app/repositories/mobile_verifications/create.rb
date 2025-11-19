# frozen_string_literal: true

module MobileVerifications
  class Create
    def self.call(mobile_number, verification_code, user)
      MobileVerification.for_user(user).active.find_each(&:mark_as_expired!)

      MobileVerification.create!(
        mobile_number: mobile_number,
        code: verification_code,
        user: user
      )
    end
  end
end
