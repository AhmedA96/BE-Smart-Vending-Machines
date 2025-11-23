# frozen_string_literal: true

class AddUniqueIndexToPaymentCustomersUserId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # Remove the old composite index
    remove_index :payment_customers,
                 name: 'index_payment_customers_on_payment_customer_number_and_user_id',
                 if_exists: true

    # Add unique index on payment_customer_number alone
    add_index :payment_customers, :payment_customer_number,
              unique: true,
              algorithm: :concurrently,
              name: 'index_payment_customers_on_payment_customer_number',
              if_not_exists: true

    # Add unique index on user_id
    add_index :payment_customers, :user_id,
              unique: true,
              algorithm: :concurrently,
              name: 'index_payment_customers_on_user_id',
              if_not_exists: true
  end

  def down
    remove_index :payment_customers, name: 'index_payment_customers_on_user_id', if_exists: true
    remove_index :payment_customers, name: 'index_payment_customers_on_payment_customer_number', if_exists: true

    add_index :payment_customers, %i[payment_customer_number user_id],
              unique: true,
              name: 'index_payment_customers_on_payment_customer_number_and_user_id',
              if_not_exists: true
  end
end
