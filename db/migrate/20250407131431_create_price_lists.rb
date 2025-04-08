# frozen_string_literal: true

class CreatePriceLists < ActiveRecord::Migration[8.0]
  def change
    create_table :price_lists do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
