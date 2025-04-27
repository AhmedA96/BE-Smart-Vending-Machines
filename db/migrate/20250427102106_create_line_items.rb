class CreateLineItems < ActiveRecord::Migration[8.0]
  def change
    create_table :line_items do |t|
      t.integer :quantity, null: false
      t.decimal :price, precision: 10, scale: 2, default: '0.0'
      t.boolean :processed, default: false, null: false
      t.decimal :price_after_discount, precision: 10, scale: 2
      t.decimal :buyx_gety_discount, precision: 10, scale: 2

      t.timestamps
    end
  end
end
