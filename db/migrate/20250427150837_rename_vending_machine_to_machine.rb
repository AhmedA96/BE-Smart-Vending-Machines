# frozen_string_literal: true

class RenameVendingMachineToMachine < ActiveRecord::Migration[8.0]
  def change
    rename_table :vending_machines, :machines
  end
end
