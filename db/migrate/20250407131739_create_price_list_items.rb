# frozen_string_literal: true

class CreatePriceListItems < ActiveRecord::Migration[8.0]
  def change
    create_table :price_list_items do |t|
      t.references :price_list, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :price, precision: 10, scale: 2, null: false
      t.timestamps
    end
  end
end
