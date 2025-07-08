# frozen_string_literal: true

class AddCountryToLocations < ActiveRecord::Migration[8.0]
  def change
    add_reference :locations, :country, foreign_key: true
  end
end
