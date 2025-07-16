# frozen_string_literal: true

class CreateWallets < ActiveRecord::Migration[8.0]
  def change
    create_table :wallets do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :balance, precision: 15, scale: 2, null: false, default: 0.0

      t.timestamps
    end
  end
end
