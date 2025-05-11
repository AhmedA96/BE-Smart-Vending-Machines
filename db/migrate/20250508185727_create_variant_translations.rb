# frozen_string_literal: true

class CreateVariantTranslations < ActiveRecord::Migration[8.0]
  def change
    create_table :variant_translations do |t|
      t.string :presentation
      t.string :locale, null: false

      t.references :variant, null: false, foreign_key: true

      t.timestamps null: false
    end
    add_index :variant_translations, [:locale], name: :index_variant_translations_on_locale
    add_index :variant_translations, %i[variant_id locale], name: :index_variant_translations_on_variant_id_and_locale,
                                                            unique: true
  end
end
