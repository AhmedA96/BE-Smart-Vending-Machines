# frozen_string_literal: true

class CreateMachineTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :machine_types do |t|
      t.string :name, null: false
      t.integer :capacity, null: false
      t.boolean :has_temperature_control, default: false
      t.timestamps
    end

    add_index :machine_types, :name, unique: true
  end
end
