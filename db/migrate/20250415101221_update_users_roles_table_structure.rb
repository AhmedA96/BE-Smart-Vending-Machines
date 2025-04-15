# frozen_string_literal: true

class UpdateUsersRolesTableStructure < ActiveRecord::Migration[8.0]
  def change
    remove_index :users_roles, name: 'index_users_roles_on_user_id_and_role_id' # rubocop:disable Rails/ReversibleMigration
    remove_index :users_roles, name: 'index_users_roles_on_user_id' # rubocop:disable Rails/ReversibleMigration

    change_table :users_roles do |t|
      t.primary_key :key
    end

    add_index :users_roles, %i[user_id role_id], name: 'index_unique_user_role', unique: true
  end
end
