# frozen_string_literal: true

class CreateMachineTranslations < ActiveRecord::Migration[8.0]
  def change
    create_table :machine_translations do |t|
      t.string :name
      t.string :locale, null: false

      t.references :machine, null: false, foreign_key: true, index: false

      t.timestamps null: false
    end
    add_index :machine_translations, :locale, name: :index_machine_translations_on_locale
    add_index :machine_translations, %i[machine_id locale],
              name: :index_machine_translations_on_machine_id_and_locale, unique: true
  end
end
