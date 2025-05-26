# frozen_string_literal: true

class CreatePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_methods do |t|
      t.boolean :active, default: true, null: false
      t.string  :description
      t.string  :name, null: false
      t.string  :presentation

      t.timestamps
    end
  end
end
