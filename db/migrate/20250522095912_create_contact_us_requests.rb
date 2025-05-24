# frozen_string_literal: true

class CreateContactUsRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_us_requests do |t|
      t.string :full_name
      t.string :email
      t.string :phone_number
      t.string :company_name

      t.timestamps
    end
  end
end
