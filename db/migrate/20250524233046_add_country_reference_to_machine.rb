# frozen_string_literal: true

class AddCountryReferenceToMachine < ActiveRecord::Migration[8.0]
  def change
    add_reference :machines, :country, foreign_key: true
  end
end
