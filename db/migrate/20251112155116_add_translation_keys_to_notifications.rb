# frozen_string_literal: true

class AddTranslationKeysToNotifications < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_column :notifications, :translation_key, :string
    add_column :notifications, :translation_params, :jsonb, default: {}

    add_index :notifications, :translation_key, algorithm: :concurrently
  end

  def down
    remove_index :notifications, :translation_key
    remove_column :notifications, :translation_key
    remove_column :notifications, :translation_params
  end
end
