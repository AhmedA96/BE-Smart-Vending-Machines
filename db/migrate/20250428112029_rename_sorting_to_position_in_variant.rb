# frozen_string_literal: true

class RenameSortingToPositionInVariant < ActiveRecord::Migration[8.0]
  def change
    rename_column :variants, :sorting, :position
  end
end
