# frozen_string_literal: true

class AddBrandsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_reference :products, :brand, foreign_key: true
  end
end
