# frozen_string_literal: true

class ModifyDoorkeeperTablesForClientlessAuth < ActiveRecord::Migration[8.0]
  def up
    # Remove the foreign key constraint from oauth_access_tokens
    remove_foreign_key :oauth_access_tokens, :oauth_applications

    # Make application_id nullable
    change_column_null :oauth_access_tokens, :application_id, true
  end

  def down
    # Add back the foreign key constraint
    add_foreign_key(
      :oauth_access_tokens,
      :oauth_applications,
      column: :application_id
    )

    # Make application_id non-nullable again
    change_column_null :oauth_access_tokens, :application_id, false
  end
end
