# frozen_string_literal: true

class RenameExternalMachineIdToMachineuuidInMachines < ActiveRecord::Migration[8.0]
  def change
    rename_column :machines, :machineuuid, :machineuuid
  end
end
