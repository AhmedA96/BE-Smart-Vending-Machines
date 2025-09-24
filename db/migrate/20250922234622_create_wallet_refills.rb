# frozen_string_literal: true

class CreateWalletRefills < ActiveRecord::Migration[8.0]
  def change
    create_table :wallet_refills do |t|
      t.references :wallet, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :payment_method_id
      t.integer :card_id
      t.string :token_id
      t.string :status, default: 'pending'

      t.timestamps
    end
  end
end
