# frozen_string_literal: true

class AddLocationToVendingMachines < ActiveRecord::Migration[8.0]
  def change
    remove_column :vending_machines, :latitude, :float
    remove_column :vending_machines, :longitude, :float

    add_column :vending_machines, :location, :geography, limit: { srid: 4326, type: :st_point, geographic: true }
    add_index :vending_machines, :location, using: :gist

    add_column :vending_machines, :location_updated_at, :datetime
  end
end
