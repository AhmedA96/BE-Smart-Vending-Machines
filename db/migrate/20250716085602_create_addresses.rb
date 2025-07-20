# frozen_string_literal: true

class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.string  :address
      t.string  :appart_number,   null: false, default: 'N/A'
      t.string  :building_number, null: false, default: 'N/A'
      t.string  :city
      t.boolean :default,         null: false, default: false
      t.string  :floor_number,    null: false, default: 'N/A'
      t.string  :name,            null: false, default: ''
      t.integer :country_id
      t.integer :user_id, null: false

      t.timestamps
    end
  end
end
