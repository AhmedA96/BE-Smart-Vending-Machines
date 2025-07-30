# frozen_string_literal: true

module Api
  module V1
    module Users
      class PasswordsController < ApplicationController
        rate_limit to: 3, within: 5.minutes, with: lambda {
          render_error(I18n.t('errors.too_many_requests'), :too_many_requests)
        }, only: %i[forgot_password]

        before_action :find_user_by_mobile, only: [:forgot_password]
        before_action :find_user_by_mobile_and_token, only: [:reset_password]

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
          code = Verification::Mobile.generate_verification_code
          @user.update!(reset_password_token: code, reset_password_sent_at: Time.current)

          Verification::Mobile.send_code(params[:mobile_number], @user)
          render json: { message: I18n.t('user.password_reset.code_sent') }
        end

        def reset_password
          if @user.update(change_password_params.merge(reset_password_token: nil, reset_password_sent_at: nil))
            render json: { success: true }
          else
            render json: { error: @user.errors.full_messages.first }, status: :unprocessable_content
          end
        end

        private

        def change_password_params
          params.permit(:password, :password_confirmation)
        end

        def find_user_by_mobile
          @user = User.find_by(mobile_number: params[:mobile_number])
          render json: { error: I18n.t('user.wrong_mobile') }, status: :not_found unless @user
        end

        def find_user_by_mobile_and_token
          @user = User.find_by(
            mobile_number: params[:mobile_number],
            reset_password_token: params[:code]
          )
          return if @user

          render json: {
            error: I18n.t('user.password_reset.wrong_or_expired_code')
          }, status: :unprocessable_content
        end

        def handle_rate_limit_exceeded
          render_error(I18n.t('errors.too_many_requests'), :too_many_requests)
        end
      end
    end
  end
end
