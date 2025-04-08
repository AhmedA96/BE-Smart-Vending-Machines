# frozen_string_literal: true

class CreateMachineProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :machine_products do |t|
      t.references :vending_machine, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :stock, default: 0

      t.timestamps
    end

    add_index :machine_products, %i[vending_machine_id product_id], unique: true
  end
end
