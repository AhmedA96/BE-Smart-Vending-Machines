# frozen_string_literal: true

class RenameVendingMachineIdToMachineId < ActiveRecord::Migration[8.0]
  def change
    rename_column :machine_items, :vending_machine_id, :machine_id
    rename_column :machine_statuses, :vending_machine_id, :machine_id
    rename_column :orders, :vending_machine_id, :machine_id
  end
end
