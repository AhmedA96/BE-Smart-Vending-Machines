# frozen_string_literal: true

class CreatePriceLists < ActiveRecord::Migration[8.0]
  def change
    create_table :price_lists do |t|
      t.references :vending_machine, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
  end
end
