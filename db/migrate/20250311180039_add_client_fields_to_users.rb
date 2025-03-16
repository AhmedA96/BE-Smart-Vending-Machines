# frozen_string_literal: true

class AddClientFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    # Add missing columns
    add_column :users, :client_id, :integer
    add_column :users, :client_country_id, :bigint

    # Add missing index
    add_index :users, %i[mobile_number client_id], unique: true

    # Modify existing columns
    change_column_default :users, :verified, false # rubocop:disable Rails/ReversibleMigration
    change_column_null :users, :verified, false
    change_column_default :users, :locale, 'en' # rubocop:disable Rails/ReversibleMigration
  end
end
