# frozen_string_literal: true

class CreateBrands < ActiveRecord::Migration[8.0]
  def change
    create_table :brands do |t|
      t.string :name
      t.text :description
      t.string :logo
      t.string :background

      t.timestamps
    end
  end
end
