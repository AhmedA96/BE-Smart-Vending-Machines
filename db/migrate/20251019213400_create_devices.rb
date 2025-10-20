# frozen_string_literal: true

class CreateDevices < ActiveRecord::Migration[8.0]
  def change
    create_table :devices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.string :platform, null: false
      t.boolean :active, default: true
      t.datetime :last_used_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :devices, :token, unique: true
    add_index :devices, %i[user_id active]
    add_index :devices, %i[user_id platform]
  end
end
