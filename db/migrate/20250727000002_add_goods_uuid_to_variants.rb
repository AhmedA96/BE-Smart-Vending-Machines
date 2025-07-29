# frozen_string_literal: true

class AddGoodsUuidToVariants < ActiveRecord::Migration[8.0]
  def change
    add_column :variants, :goods_uuid, :string
    add_index :variants, :goods_uuid, unique: true
  end
end
