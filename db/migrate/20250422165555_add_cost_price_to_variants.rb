# frozen_string_literal: true

class AddCostPriceToVariants < ActiveRecord::Migration[8.0]
  def change
    add_column :variants, :cost_price, :decimal, precision: 10, scale: 2, default: 0
  end
end
