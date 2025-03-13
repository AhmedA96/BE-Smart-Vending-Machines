# frozen_string_literal: true

class RemoveUnusedColumnsFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :gender, :string
    remove_column :users, :nationality, :string
    remove_column :users, :membership_number, :string
    remove_column :users, :client_id, :integer
    remove_column :users, :client_country_id, :bigint
  end
end
