# frozen_string_literal: true

class AddCoordinatesToLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :coordinates, :geography,
               limit: { srid: 4326, type: 'st_point', geographic: true }

    add_index :locations, :coordinates, using: :gist,
                                        name: 'index_locations_on_coordinates'
  end
end
