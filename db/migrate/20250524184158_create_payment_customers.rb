# frozen_string_literal: true

class CreatePaymentCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_customers do |t|
      t.string :payment_customer_number, null: false
      t.integer :user_id
      t.timestamps
    end

    add_index :payment_customers, %i[payment_customer_number user_id],
              name: :index_payment_customers_on_payment_customer_number_and_user_id, unique: true
  end
end
