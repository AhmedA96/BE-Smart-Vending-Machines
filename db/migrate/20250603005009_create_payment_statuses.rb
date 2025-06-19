# frozen_string_literal: true

class CreatePaymentStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_statuses do |t|
      t.integer :payment_transaction_id
      t.string :status, null: false
      t.string :transaction_url
      t.datetime :transaction_created_at

      t.timestamps
    end
  end
end
