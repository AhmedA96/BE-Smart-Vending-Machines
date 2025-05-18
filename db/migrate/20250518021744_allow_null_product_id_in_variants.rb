# frozen_string_literal: true

class AllowNullProductIdInVariants < ActiveRecord::Migration[8.0]
  def up
    change_column_null :variants, :product_id, true
  end

  def down
    change_column_null :variants, :product_id, false
  end
end
