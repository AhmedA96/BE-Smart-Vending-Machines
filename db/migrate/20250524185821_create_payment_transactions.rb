# frozen_string_literal: true

class CreatePaymentTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_transactions do |t|
      t.string :charge_id, null: false
      t.integer :payment_customer_id
      t.integer :payment_id

      t.timestamps
    end

    add_index :payment_transactions, :charge_id
    add_index :payment_transactions, :payment_customer_id
    add_index :payment_transactions, :payment_id
  end
end
