# frozen_string_literal: true

class CreateVendors < ActiveRecord::Migration[8.0]
  def change
    create_table :vendors do |t|
      t.string :name
      t.string :contact_person
      t.string :phone_number
      t.string :email
      t.text :address

      t.timestamps
    end
  end
end
