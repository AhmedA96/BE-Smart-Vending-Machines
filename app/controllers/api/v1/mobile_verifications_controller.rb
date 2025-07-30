# frozen_string_literal: true

module Api
  module V1
    class MobileVerificationsController < ApplicationController
      before_action :find_user_by_mobile, only: %i[verify_code send_verification_code]

      def send_verification_code
        mobile_number = params[:mobile_number]

        verification = MobileVerification.find_or_create_by!(
          mobile_number: mobile_number,
          user_id: @user.id,
          code: Verification::Mobile.generate_verification_code
        )

        render json: { verification_code: verification.code }, status: :ok
      end

      def verify_code
        return head :not_found unless @user

        mobile_number = @user.mobile_number
        code = params[:verification_code]
        @mobile_verification = MobileVerification.find_by(
          mobile_number:,
          code:,
          user_id: @user.id
        )

        if @mobile_verification.nil? || @mobile_verification.expired?
          return render_error(I18n.t('errors.password_reset.wrong_or_expired_code'),
                              :unprocessable_entity)
        end

        @mobile_verification.update!(verified: true, expired: true)
        @user.update!(verified: true)
        head :ok
      end

      private

      def find_user_by_mobile
        @user = User.find_by(mobile_number: params[:mobile_number])
        render json: { error: I18n.t('user.authentication.invalid_login') }, status: :not_found unless @user
      end
    end
  end
end
