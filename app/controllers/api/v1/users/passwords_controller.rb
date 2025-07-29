# frozen_string_literal: true

module Api
  module V1
    module Users
      class PasswordsController < ApplicationController
        rate_limit to: 3, within: 5.minutes, with: lambda {
          render_error(I18n.t('errors.too_many_requests'), :too_many_requests)
        }, only: %i[forgot_password]

        def change_password
          unless current_user.valid_password?(params[:current_password])
            return render json: { error: I18n.t('user.wrong_password') }, status: :unprocessable_content
          end

          if current_user.update(change_password_params)
            render json: { message: I18n.t('user.password_changed_successfully') }
          else
            render json: { error: current_user.errors }, status: :unprocessable_content
          end
        end

        def forgot_password
          user = User.find_by(mobile_number: params[:mobile_number])
          return render json: { error: I18n.t('user.wrong_mobile') }, status: :not_found unless user

          code = Verification::Mobile.generate_verification_code
          user.update!(reset_password_token: code, reset_password_sent_at: Time.current)

          Verification::Mobile.send_code(params[:mobile_number], user)
          render json: { message: I18n.t('user.password_reset.code_sent') }
        end

        def reset_password
          user = User.find_by(
            mobile_number: params[:mobile_number],
            reset_password_token: params[:code]
          )

          unless user&.reset_password_sent_at&.> 10.minutes.ago
            return render json: { error: I18n.t('user.password_reset.wrong_or_expired_code') },
                          status: :unprocessable_content
          end

          if user.update(change_password_params.merge(reset_password_token: nil, reset_password_sent_at: nil))
            render json: { success: true }
          else
            render json: { error: user.errors.full_messages.first }, status: :unprocessable_content
          end
        end

        private

        def change_password_params
          params.permit(:password, :password_confirmation)
        end
      end
    end
  end
end
