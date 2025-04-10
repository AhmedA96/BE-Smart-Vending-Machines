# frozen_string_literal: true

class UpdateProductsTable < ActiveRecord::Migration[8.0]
  def change
    # Remove old columns
    remove_column :products, :is_active, :boolean
    remove_column :products, :images, :jsonb

    # Change column types
    change_column :products, :description, :string # rubocop:disable Rails/ReversibleMigration

    # Add new columns
    add_column :products, :status, :string
    add_column :products, :slug, :string
    add_column :products, :deleted_at, :datetime
    add_column :products, :total_rate, :float
    add_column :products, :max_orderable_quantity, :integer
    add_column :products, :sorting, :integer, default: 1

    # Add new indexes
    add_index :products, :created_at
    add_index :products, :deleted_at
    add_index :products, :sorting
  end
end
