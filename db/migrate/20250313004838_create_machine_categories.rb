# frozen_string_literal: true

class CreateMachineCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :machine_categories do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
