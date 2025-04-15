# frozen_string_literal: true

class CreateProductCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :product_categories do |t|
      t.references :product, foreign_key: true, index: true
      t.references :category, foreign_key: true, index: true

      t.timestamps
    end

    add_index :product_categories, %i[product_id category_id], unique: true,
                                                               name: 'index_product_categories_uniqueness'
  end
end
