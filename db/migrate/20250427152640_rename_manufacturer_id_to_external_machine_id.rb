# frozen_string_literal: true

class RenameManufacturerIdToExternalMachineId < ActiveRecord::Migration[8.0]
  def change
    rename_column :machines, :manufacturer_id, :external_machine_id
  end
end
