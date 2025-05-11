# frozen_string_literal: true

class CreateBrandTranslations < ActiveRecord::Migration[8.0]
  def change
    create_table :brand_translations do |t|
      t.string :presentation
      t.text :description

      t.string :locale, null: false
      t.references :brand, null: false, foreign_key: true, index: false

      t.timestamps null: false
    end

    add_index :brand_translations, :locale, name: :index_brand_translations_on_locale
    add_index :brand_translations, %i[brand_id locale],
              name: :index_brand_translations_on_brand_id_and_locale, unique: true
  end
end
