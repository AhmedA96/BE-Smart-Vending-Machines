# frozen_string_literal: true

class AddVariantToMachineProducts < ActiveRecord::Migration[8.0]
  def change
    add_reference :machine_products, :variant, foreign_key: true

    # Remove the old unique index
    remove_index :machine_products, %i[vending_machine_id product_id]

    # Add new unique index including variant_id
    add_index :machine_products, %i[vending_machine_id product_id variant_id],
              unique: true, name: 'index_machine_products_on_vm_product_variant'
  end
end
