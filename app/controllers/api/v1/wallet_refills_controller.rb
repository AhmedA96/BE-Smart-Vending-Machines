# frozen_string_literal: true

module Api
  module V1
    class WalletRefillsController < ApplicationController
      before_action :current_user
      before_action :find_wallet, only: %i[create]

      def create
        render_error(
          I18n.t('errors.wallet.not_working_now'),
          :unprocessable_content
        )
        @wallet_refill = WalletRefills::Create.call(params, @user_wallet)

        complete_charge_operation
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
