# frozen_string_literal: true

class AddIndexesForFavoritesApi < ActiveRecord::Migration[8.0]
  def change
    add_index :line_items, %i[variant_id order_id]
    add_index :orders, %i[user_id created_at]
  end
end
