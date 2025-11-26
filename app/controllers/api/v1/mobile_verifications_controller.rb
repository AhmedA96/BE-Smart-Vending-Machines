# frozen_string_literal: true

module Api
  module V1
    class MobileVerificationsController < ApplicationController
      rate_limit to: 5, within: 5.minutes, with: lambda {
        render_error(I18n.t('errors.too_many_requests'), :too_many_requests)
      }, only: %i[send_verification_code]

      before_action :find_user_by_mobile, only: %i[verify_code send_verification_code]

      def send_verification_code
        mobile_number = params[:mobile_number]

        result = if Rails.env.production?
                   Verification::Mobile.send_code(mobile_number, @user)
                 else
                   verification_code = '123456'
                   MobileVerifications::Create.call(mobile_number, verification_code, @user)
                   { success: true, code: verification_code }
                 end

        if result[:success]
          response_data = { message: I18n.t('verification.mobile.code_sent') }

          response_data[:verification_code] = result[:code] unless Rails.env.production?

          render json: response_data, status: :ok
        else
          render json: {
            error: I18n.t('verification.mobile.errors.send_failed'),
            details: result[:error]
          }, status: :unprocessable_content
        end
      end

      def verify_code
        return head :not_found unless @user

        mobile_number = @user.mobile_number
        code = params[:verification_code]

        @mobile_verification = MobileVerification.find_by(
          mobile_number: mobile_number,
          code: code,
          user_id: @user.id
        )

        if @mobile_verification.nil?
          return render_error(
            I18n.t('verification.mobile.errors.code_not_found'),
            :unprocessable_entity
          )
        end

        if @mobile_verification.expired?
          return render_error(
            I18n.t('verification.mobile.errors.code_expired'),
            :unprocessable_entity
          )
        end

        @mobile_verification.update!(verified: true, expired: true)
        @user.update!(verified: true)

        render json: {
          message: I18n.t('verification.mobile.verified_successfully')
        }, status: :ok
      end

      private

      def find_user_by_mobile
        @user = User.find_by(mobile_number: params[:mobile_number])

        return if @user

        render json: {
          error: I18n.t('user.authentication.invalid_login')
        }, status: :not_found
      end

      def render_error(message, status)
        render json: { error: message }, status: status
      end
    end
  end
end
