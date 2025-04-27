# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table 'orders', force: :cascade do |t|
      t.string 'number', null: false
      t.decimal 'total', precision: 10, scale: 2, default: '0.0'
      t.decimal 'items_total', precision: 10, scale: 2, default: '0.0'
      t.decimal 'total_tax', precision: 10, scale: 2, default: '0.0'
      t.decimal 'total_discounts', precision: 10, scale: 2, default: '0.0'
      t.string 'payment_method'
      t.string 'status'
      t.string 'dispense_status'
      t.jsonb 'machine_response'
      t.datetime 'completed_at'
      t.datetime 'deleted_at'

      t.timestamps
    end
  end
end
