# frozen_string_literal: true

class RenameSortingToPositionInProduct < ActiveRecord::Migration[8.0]
  def change
    rename_column :products, :sorting, :position
  end
end
