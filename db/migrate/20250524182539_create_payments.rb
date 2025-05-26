# frozen_string_literal: true

class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.decimal  :amount, precision: 10, scale: 2, null: false
      t.datetime :deleted_at
      t.string   :message
      t.string   :status, null: false, default: 'pending'
      t.integer  :card_id
      t.integer  :order_id
      t.integer  :payment_method_id
      t.string   :token_id

      t.timestamps
    end
  end
end
