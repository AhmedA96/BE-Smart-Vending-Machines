# frozen_string_literal: true

class UpdateMachineTranslations < ActiveRecord::Migration[8.0]
  def change
    add_column :machine_translations, :description, :text
    add_column :machine_translations, :presentation, :string

    add_column :machines, :description, :text
    add_column :machines, :presentation, :string
  end
end
