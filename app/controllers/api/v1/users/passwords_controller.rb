# frozen_string_literal: true

module Api
  module V1
    module Users
      class PasswordsController < ApplicationController
        rate_limit to: 3, within: 5.minutes, with: lambda {
          render_error(I18n.t('errors.too_many_requests'), :too_many_requests)
        }, only: %i[forgot_password]

        before_action :find_user_by_mobile, only: %i[forgot_password reset_password]
        before_action :current_user, only: %i[change_password]

        def change_password
          unless current_user.valid_password?(params[:current_password])
            return render json: {
              error: I18n.t('user.password_reset.wrong_current_password')
            }, status: :unauthorized
          end

          if current_user.update(password_params)
            render json: {
              message: I18n.t('user.password_changed_successfully')
            }, status: :ok
          else
            render json: {
              error: current_user.errors.full_messages.first
            }, status: :unprocessable_entity
          end
        end

        def forgot_password
          result = PasswordReset::SendCode.call(@user)

          if result[:success]
            response_data = {
              message: I18n.t('user.password_reset.code_sent')
            }

            response_data[:code] = result[:code] unless Rails.env.development?

            render json: response_data, status: :ok
          else
            render json: {
              error: I18n.t('user.password_reset.send_failed'),
              details: result[:error]
            }, status: :unprocessable_entity
          end
        end

        def reset_password
          result = PasswordReset::VerifyAndReset.call(
            user: @user,
            code: params[:code],
            new_password: params[:password],
            password_confirmation: params[:password_confirmation]
          )

          if result[:success]
            render json: {
              message: I18n.t('user.password_reset.reset_successfully')
            }, status: :ok
          else
            render json: {
              error: result[:error]
            }, status: :unprocessable_entity
          end
        end

        private

        def password_params
          params.permit(:password, :password_confirmation)
        end

        def find_user_by_mobile
          @user = User.find_by(mobile_number: params[:mobile_number])

          return if @user

          render json: {
            error: I18n.t('errors.user.mobile_not_found')
          }, status: :not_found
        end
      end
    end
  end
end
