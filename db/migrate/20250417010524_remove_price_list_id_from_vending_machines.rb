# frozen_string_literal: true

class RemovePriceListIdFromVendingMachines < ActiveRecord::Migration[8.0]
  def change
    remove_reference :vending_machines, :price_list, foreign_key: true
  end
end
