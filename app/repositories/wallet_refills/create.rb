# frozen_string_literal: true

module WalletRefills
  class Create
    def self.call(params, user_wallet)
      create_payment(params, user_wallet)
    end

    def self.create_payment(params, user_wallet)
      WalletRefill.create!(
        wallet: user_wallet,
        amount: params[:amount],
        payment_method_id: params[:payment_method_id],
        card_id: params[:card_id],
        token_id: params[:token_id]
      )
    end
  end
end
