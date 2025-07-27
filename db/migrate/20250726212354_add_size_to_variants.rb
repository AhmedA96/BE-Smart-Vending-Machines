# frozen_string_literal: true

class AddSizeToVariants < ActiveRecord::Migration[8.0]
  def change
    add_column :variants, :size, :string

    add_index :variants, :size
    add_index :variants, %i[product_id size], unique: true, name: 'index_variants_on_product_size'
  end
end
