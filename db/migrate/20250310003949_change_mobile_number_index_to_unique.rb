# frozen_string_literal: true

class ChangeMobileNumberIndexToUnique < ActiveRecord::Migration[8.0]
  def change
    remove_index :users, :mobile_number
    add_index :users, :mobile_number, unique: true
  end
end
