# frozen_string_literal: true

class CreateMachineCategoryTranslations < ActiveRecord::Migration[8.0]
  def change
    create_table :machine_category_translations do |t|
      t.string :presentation
      t.text :description

      t.string :locale, null: false
      t.references :machine_category, null: false, foreign_key: true, index: false

      t.timestamps null: false
    end

    add_index :machine_category_translations, :locale, name: :index_machine_category_translations_on_locale
    add_index :machine_category_translations, %i[machine_category_id locale],
              name: :index_mc_translations_on_machine_category_id_and_locale, unique: true
  end
end
