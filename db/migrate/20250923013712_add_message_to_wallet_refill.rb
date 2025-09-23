# frozen_string_literal: true

class AddMessageToWalletRefill < ActiveRecord::Migration[8.0]
  def change
    add_column :wallet_refills, :message, :string
  end
end
