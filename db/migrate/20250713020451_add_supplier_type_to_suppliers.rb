# frozen_string_literal: true

class AddSupplierTypeToSuppliers < ActiveRecord::Migration[8.0]
  def change
    add_column :suppliers, :supplier_type, :string, default: ''
    add_index :suppliers, :supplier_type
  end
end
