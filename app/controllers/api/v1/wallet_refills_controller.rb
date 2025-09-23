# frozen_string_literal: true

module Api
  module V1
    class WalletRefillsController < ApplicationController
      before_action :current_user
      before_action :find_wallet, only: %i[create]

      def create
        @wallet_refill = WalletRefills::Create.call(params, @user_wallet)

        complete_charge_operation
      end

      def valid_amounts
        render json: { valid_top_up_amounts: WalletRefill::VALID_TOP_UP_AMOUNTS }
      end

      private

      def complete_charge_operation
        @wallet_refill.complete!
      end

      def find_wallet
        @user_wallet = current_user.wallet
      end

      def wallet_refill_params
        params.permit(:amount, :payment_method_id, :card_id, :token_id, :wallet_id)
      end
    end
  end
end
