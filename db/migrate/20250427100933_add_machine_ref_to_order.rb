# frozen_string_literal: true

class AddMachineRefToOrder < ActiveRecord::Migration[8.0]
  def change
    add_reference :orders, :vending_machine, null: false, foreign_key: true # rubocop:disable Rails/NotNullColumn
  end
end
