# frozen_string_literal: true

class CreateCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :countries do |t|
      t.string :name
      t.string :iso2
      t.string :currency
      t.string :time_zone
      t.decimal :vat_percentage, precision: 10, scale: 2, default: 0.0
      t.timestamps
    end
  end
end
