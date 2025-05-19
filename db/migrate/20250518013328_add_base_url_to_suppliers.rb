# frozen_string_literal: true

class AddBaseUrlToSuppliers < ActiveRecord::Migration[8.0]
  def change
    add_column :suppliers, :base_url, :string
  end
end
