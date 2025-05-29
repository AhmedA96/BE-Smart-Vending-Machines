# frozen_string_literal: true

class CreateCountryTranslations < ActiveRecord::Migration[8.0]
  def change
    create_table :country_translations do |t|
      t.string :presentation
      t.string :currency

      t.string :locale, null: false
      t.references :country, null: false, foreign_key: true, index: false

      t.timestamps
    end

    add_index :country_translations, :locale, name: :index_country_translations_on_locale
    add_index :country_translations, %i[country_id locale],
              name: :index_country_translations_on_country_id_and_locale, unique: true
  end
end
