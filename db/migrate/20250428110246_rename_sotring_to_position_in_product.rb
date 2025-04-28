# frozen_string_literal: true

class RenameSotringToPositionInProduct < ActiveRecord::Migration[8.0]
  def change
    rename_column :products, :sorting, :position
  end
end
