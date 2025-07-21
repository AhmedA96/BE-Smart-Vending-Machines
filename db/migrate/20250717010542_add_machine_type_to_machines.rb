# frozen_string_literal: true

class AddMachineTypeToMachines < ActiveRecord::Migration[8.0]
  def change
    add_reference :machines, :machine_type, foreign_key: true
  end
end
