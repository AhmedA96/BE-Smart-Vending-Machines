# frozen_string_literal: true

class AddQrCodeTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :qr_code_token, :string
    add_index :users, :qr_code_token
  end
end
