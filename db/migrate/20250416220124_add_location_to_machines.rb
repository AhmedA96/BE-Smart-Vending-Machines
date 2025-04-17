# frozen_string_literal: true

class AddLocationToMachines < ActiveRecord::Migration[8.0]
  def change
    add_reference :vending_machines, :location, foreign_key: true

    remove_column :vending_machines, :location_name # rubocop:disable Rails/ReversibleMigration
  end
end
