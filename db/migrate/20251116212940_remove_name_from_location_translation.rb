# frozen_string_literal: true

class RemoveNameFromLocationTranslation < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :location_translations, :name, :string }
  end
end
