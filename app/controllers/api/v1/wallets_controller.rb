# frozen_string_literal: true

module Api
  module V1
    class WalletsController < ApplicationController
      before_action :current_user

      def my_wallet
        @user_wallet = @current_user.wallet

        render json: @user_wallet, status: :ok
      end
    end
  end
end
