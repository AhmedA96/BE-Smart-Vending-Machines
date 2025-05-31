# frozen_string_literal: true

class CreateMobileVerifications < ActiveRecord::Migration[8.0]
  def change
    create_table :mobile_verifications do |t|
      t.references :user
      t.string :code
      t.boolean :expired, default: false, null: false
      t.datetime :expires_at
      t.string :mobile_number
      t.boolean :verified, default: false, null: false

      t.timestamps
    end
  end
end
