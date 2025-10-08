# frozen_string_literal: true

class AddCountryCodeToCountry < ActiveRecord::Migration[8.0]
  def change
    add_column :countries, :country_code, :string, null: false, default: ''
  end
end
