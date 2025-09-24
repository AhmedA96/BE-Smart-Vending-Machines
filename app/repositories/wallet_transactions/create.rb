# frozen_string_literal: true

module WalletTransactions
  class Create
    def self.call(amount, transaction_type, user_wallet)
      create_transaction(amount, transaction_type, user_wallet)
    end

    def self.create_transaction(amount, transaction_type, user_wallet)
      WalletTransaction.create!(
        wallet: user_wallet,
        amount:,
        transaction_type:
      )
    end
  end
end
