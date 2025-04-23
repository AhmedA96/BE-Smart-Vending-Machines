# frozen_string_literal: true

class AddLineNumberToMachineProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :machine_products, :line_number, :integer
  end
end
