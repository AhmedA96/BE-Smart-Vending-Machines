# frozen_string_literal: true

class AddReservedStockToMachineItems < ActiveRecord::Migration[8.0]
  def change
    add_column :machine_items, :reserved_stock, :integer, default: 0, null: false
  end
end
