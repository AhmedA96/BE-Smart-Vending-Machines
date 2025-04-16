# frozen_string_literal: true

class UpdatePriceListItemsToUseVariants < ActiveRecord::Migration[8.0]
  def change
    add_reference :price_list_items, :variant, foreign_key: true

    add_index :price_list_items, %i[price_list_id variant_id], unique: true
  end
end
