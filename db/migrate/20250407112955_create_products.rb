# frozen_string_literal: true

class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :is_active, default: true
      t.jsonb :images

      t.timestamps
    end

    add_index :products, :name
    add_index :products, :is_active
  end
end
