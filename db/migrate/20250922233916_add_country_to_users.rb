# frozen_string_literal: true

class AddCountryToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :country, foreign_key: true
  end
end
