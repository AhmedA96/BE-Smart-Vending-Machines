# frozen_string_literal: true

class AddOrderRefToLineItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :line_items, :order, foreign_key: true
  end
end
