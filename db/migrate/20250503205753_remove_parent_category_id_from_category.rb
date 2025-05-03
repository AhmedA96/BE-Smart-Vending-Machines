# frozen_string_literal: true

class RemoveParentCategoryIdFromCategory < ActiveRecord::Migration[8.0]
  def change
    remove_column :categories, :parent_category_id # rubocop:disable Rails/ReversibleMigration
  end
end
