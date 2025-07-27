# frozen_string_literal: true

class RenameExternalMachineIdToMachineuuidInMachines < ActiveRecord::Migration[8.0]
  def change
    rename_column :machines, :external_machine_id, :machineuuid
  end
end
