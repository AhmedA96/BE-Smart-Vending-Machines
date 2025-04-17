# frozen_string_literal: true

class RenameLocationToCoordinatesInMachines < ActiveRecord::Migration[8.0]
  def change
    rename_column :vending_machines, :location, :coordinates
  end
end
