# frozen_string_literal: true

class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name
      t.boolean :active, default: true, null: false
      t.references :parent_category, foreign_key: { to_table: :categories }, index: true
      t.string  :presentation
      t.integer :position, default: 0

      t.timestamps
    end
  end
end
