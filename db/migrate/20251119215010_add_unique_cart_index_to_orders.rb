# frozen_string_literal: true

class AddUniqueCartIndexToOrders < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :orders, %i[user_id machine_id status], unique: true,
                                                      where: "status = 'cart' AND user_id IS NOT NULL", name: 'index_orders_on_user_machine_cart_uniqueness', algorithm: :concurrently
  end
end
