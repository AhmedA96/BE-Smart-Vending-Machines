# frozen_string_literal: true

class AddReadToContactUsRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :contact_us_requests, :read, :boolean, default: false, null: false
    add_index :contact_us_requests, :read
  end
end
