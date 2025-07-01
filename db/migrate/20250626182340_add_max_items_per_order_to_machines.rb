# frozen_string_literal: true

class AddMaxItemsPerOrderToMachines < ActiveRecord::Migration[8.0]
  def change
    add_column :machines, :max_items_per_order, :integer, default: nil
  end
end
