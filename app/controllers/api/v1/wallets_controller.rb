# frozen_string_literal: true

module Api
  module V1
    class WalletsController < ApplicationController
      before_action :current_user

      def index
        if current_user.wallet.present?
          @wallet = current_user.wallet
          render json: @wallet
        else
          render json: { error: 'Wallet not found' }, status: :not_found
        end
      end
    end
  end
end
