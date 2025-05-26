# frozen_string_literal: true

class CreatePaymentCards < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_cards do |t|
      t.string :brand
      t.string :category
      t.boolean :default, default: false
      t.integer :exp_month
      t.integer :exp_year
      t.string :fingerprint
      t.string :first_eight
      t.string :first_six
      t.string :funding
      t.string :last_four
      t.string :name
      t.string :scheme
      t.string :card_id, null: false
      t.string :payment_agreement_id
      t.integer :payment_customer_id
      t.timestamps
    end

    add_index :payment_cards, :card_id, unique: true
    add_index :payment_cards, :payment_customer_id
  end
end
