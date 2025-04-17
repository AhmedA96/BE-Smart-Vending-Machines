# frozen_string_literal: true

class RemoveProductFromMachineProducts < ActiveRecord::Migration[8.0]
  def change
    # Remove product foreign key and index
    remove_reference :machine_products, :product, foreign_key: true

    # Change variant_id to be non-nullable
    change_column_null :machine_products, :variant_id, false

    add_index :machine_products, %i[vending_machine_id variant_id], unique: true
  end
end
