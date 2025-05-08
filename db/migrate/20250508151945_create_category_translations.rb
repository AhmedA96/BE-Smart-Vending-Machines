# frozen_string_literal: true

class CreateCategoryTranslations < ActiveRecord::Migration[8.0]
  def change
    create_table :category_translations do |t|
      t.string :presentation
      t.text :description

      t.string :locale, null: false
      t.references :category, null: false, foreign_key: true, index: false

      t.timestamps null: false
    end

    add_index :category_translations, :locale, name: :index_category_translations_on_locale
    add_index :category_translations, %i[category_id locale],
              name: :index_category_translations_on_category_id_and_locale, unique: true
  end
end
