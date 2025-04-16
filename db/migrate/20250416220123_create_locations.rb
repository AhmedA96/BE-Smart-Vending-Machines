# frozen_string_literal: true

class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.string :name
      t.string :address
      t.string :city
      t.string :landmark
      t.string :state
      t.string :zip_code

      t.timestamps
    end
  end
end
