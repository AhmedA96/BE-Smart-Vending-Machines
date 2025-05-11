# frozen_string_literal: true

class CreateLocationTranslations < ActiveRecord::Migration[8.0]
  def change
    create_table :location_translations do |t|
      t.string :name
      t.string :locale, null: false

      t.references :location, null: false, foreign_key: true, index: false

      t.timestamps null: false
    end
    add_index :location_translations, :locale, name: :index_location_translations_on_locale
    add_index :location_translations, %i[location_id locale],
              name: :index_location_translations_on_location_id_and_locale, unique: true
  end
end
