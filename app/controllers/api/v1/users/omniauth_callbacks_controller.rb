# frozen_string_literal: true

module Api
  module V1
    module Users
      class OmniauthCallbacksController < ApplicationController
        skip_before_action :doorkeeper_authorize!

        def google
          result = Omniauth::Google.call(omniauth_params)
          render_oauth_response(result)
        end

        def apple
          result = Omniauth::Apple.call(omniauth_params)
          render_oauth_response(result)
        end

        private

        def omniauth_params
          params.permit(:token, :user)
        end

        def render_oauth_response(result)
          if result[:success]
            render json: result, status: :ok
          else
            render json: { error: result[:error] }, status: :unprocessable_content
          end
        end
      end
    end
  end
end
