# frozen_string_literal: true

class ChangeUserFavoritesAssociation < ActiveRecord::Migration[8.0]
  def change
    remove_reference :user_favorites, :variant, foreign_key: true
    add_reference :user_favorites, :product, foreign_key: true

    add_index :user_favorites, %i[user_id product_id], unique: true
  end
end
