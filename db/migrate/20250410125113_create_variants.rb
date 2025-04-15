# frozen_string_literal: true

class CreateVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :variants do |t|
      t.string 'sku', null: false
      t.string   'name'
      t.integer  'points'
      t.float    'weight', default: 0.0
      t.boolean  'is_master', default: false, null: false
      t.boolean  'active', default: true
      t.integer  'sorting', default: 1
      t.integer  'product_id', null: false
      t.datetime 'deleted_at'
      t.index ['sku'], name: 'index_variants_on_sku', unique: true
      t.index ['product_id'], name: 'index_variants_on_product_id'
      t.index ['deleted_at'], name: 'index_variants_on_deleted_at'
      t.index ['created_at'], name: 'index_variants_on_created_at'
      t.index ['sorting'], name: 'index_variants_on_sorting'
      t.index ['active'], name: 'index_variants_on_active'

      t.timestamps
    end
  end
end
