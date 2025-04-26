# frozen_string_literal: true

class RenameMachineProductsToMachineItems < ActiveRecord::Migration[8.0]
  def change
    rename_table :machine_products, :machine_items
  end
end
