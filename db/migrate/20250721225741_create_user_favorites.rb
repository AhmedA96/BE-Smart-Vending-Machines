# frozen_string_literal: true

class CreateUserFavorites < ActiveRecord::Migration[8.0]
  def change
    create_table :user_favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :variant, null: false, foreign_key: true
      t.timestamps
    end

    add_index :user_favorites, %i[user_id variant_id], unique: true
    add_index :user_favorites, :created_at
  end
end
