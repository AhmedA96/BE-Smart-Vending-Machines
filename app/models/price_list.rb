# frozen_string_literal: true

# == Schema Information
#
# Table name: price_lists
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class PriceList < ApplicationRecord
  has_many :price_list_items, dependent: :destroy
  has_many :products, through: :price_list_items
  has_many :vending_machines
end
