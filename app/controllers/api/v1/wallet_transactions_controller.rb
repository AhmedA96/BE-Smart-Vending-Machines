# frozen_string_literal: true

module Api
  module V1
    class WalletTransactionsController < ApplicationController
      before_action :current_user
      before_action :find_wallet, only: %i[index show]
      before_action :find_wallet_transaction, only: [:show]

      def index
        @wallet_transactions = paginate(WalletTransaction.where(wallet_id: @user_wallet.id))
      end

      def show; end

      private

      def find_wallet
        @user_wallet = current_user.wallet
      end

      def find_wallet_transaction
        @wallet_transaction = @user_wallet.wallet_transactions.find(params[:id])
      end
    end
  end
end
