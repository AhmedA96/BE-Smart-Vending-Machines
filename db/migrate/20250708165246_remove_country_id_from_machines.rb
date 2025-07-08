# frozen_string_literal: true

class RemoveCountryIdFromMachines < ActiveRecord::Migration[8.0]
  def change
    remove_column :machines, :country_id, :integer
  end
end
