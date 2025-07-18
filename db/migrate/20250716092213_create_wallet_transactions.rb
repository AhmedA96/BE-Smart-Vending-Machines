# frozen_string_literal: true

class CreateWalletTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :wallet_transactions do |t|
      t.references :wallet, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :transaction_type, null: false
      t.string :description

      t.timestamps
    end
  end
end
