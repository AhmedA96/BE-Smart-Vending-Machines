# frozen_string_literal: true

class AllowNullEmailInUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :users, :email, true
    change_column_default :users, :email, nil # rubocop:disable Rails/ReversibleMigration
  end
end
