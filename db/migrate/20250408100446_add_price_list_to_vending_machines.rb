# frozen_string_literal: true

class AddPriceListToVendingMachines < ActiveRecord::Migration[8.0]
  def change
    add_reference :vending_machines, :price_list, foreign_key: true
  end
end
