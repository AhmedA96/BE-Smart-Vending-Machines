# frozen_string_literal: true

class AddPresentationToLocation < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :presentation, :string
    add_column :location_translations, :presentation, :string
  end
end
