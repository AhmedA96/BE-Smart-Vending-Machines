# frozen_string_literal: true

class AddUserRefToOrder < ActiveRecord::Migration[8.0]
  def change
    add_reference :orders, :user, null: false, foreign_key: true, default: 0
  end
end
