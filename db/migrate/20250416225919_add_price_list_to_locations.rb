# frozen_string_literal: true

class AddPriceListToLocations < ActiveRecord::Migration[8.0]
  def change
    add_reference :locations, :price_list, foreign_key: true
  end
end
