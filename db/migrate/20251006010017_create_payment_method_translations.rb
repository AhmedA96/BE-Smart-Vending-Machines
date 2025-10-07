# frozen_string_literal: true

class CreatePaymentMethodTranslations < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_method_translations do |t|
      t.string :presentation
      t.text :description

      t.string :locale, null: false

      t.references :payment_method, null: false, foreign_key: true, index: false

      t.timestamps null: false
    end

    add_index :payment_method_translations, :locale, name: :index_payment_method_translations_on_locale
    add_index :payment_method_translations, %i[payment_method_id locale],
              name: :index_pm_translations_on_payment_method_id_and_locale, unique: true
  end
end
