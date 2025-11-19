# frozen_string_literal: true

class RemoveNameFromMachineTranslation < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :machine_translations, :name, :string }
  end
end
