# frozen_string_literal: true

class CreateVendingMachines < ActiveRecord::Migration[8.0]
  def change
    create_table :machines do |t|
      t.string :manufacturer_id
      t.string :name
      t.references :category, null: false, foreign_key: { to_table: :machine_categories }
      t.references :vendor, null: false, foreign_key: true
      t.string :location_name
      t.decimal :latitude
      t.decimal :longitude
      t.string :status
      t.datetime :installed_at
      t.datetime :last_service_date

      t.timestamps
    end
    add_index :vending_machines, :manufacturer_id, unique: true
  end
end
