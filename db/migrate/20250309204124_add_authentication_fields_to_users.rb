class AddAuthenticationFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime
    add_column :users, :name, :string
    add_column :users, :email_notification, :boolean, default: true, null: false
    add_column :users, :sms_notification, :boolean, default: true, null: false
    add_column :users, :uid, :string
    add_column :users, :provider, :string
    add_column :users, :hashed_password, :string
    add_column :users, :profile_id, :bigint
  end
end
