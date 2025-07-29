# frozen_string_literal: true

class AddPickUpCodeToOrder < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :pick_up_code, :string
  end
end
