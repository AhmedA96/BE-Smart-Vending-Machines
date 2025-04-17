# frozen_string_literal: true

class RemoveProductFromPriceListItems < ActiveRecord::Migration[8.0]
  def change
    remove_reference :price_list_items, :product, foreign_key: true
  end
end
