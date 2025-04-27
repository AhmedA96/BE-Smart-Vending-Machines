# frozen_string_literal: true

class AddVariantRefToLineItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :line_items, :variant, foreign_key: true
  end
end
