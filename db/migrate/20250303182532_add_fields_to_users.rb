class AddFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :avatar, :string
    add_column :users, :date_of_birth, :date
    add_column :users, :gender, :string
    add_column :users, :nationality, :string
    add_column :users, :locale, :string
    add_index :users, :locale
    add_column :users, :mobile_number, :string
    add_index :users, :mobile_number
    add_column :users, :verified, :boolean
    add_column :users, :last_active_at, :datetime
    add_column :users, :deleted_at, :datetime
    add_column :users, :uuid, :string
    add_index :users, :uuid, unique: true
    add_column :users, :membership_number, :string
  end
end
