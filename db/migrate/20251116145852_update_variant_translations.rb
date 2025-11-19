# frozen_string_literal: true

class UpdateVariantTranslations < ActiveRecord::Migration[8.0]
  def change
    add_column :variant_translations, :size, :string
  end
end
