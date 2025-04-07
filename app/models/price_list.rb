# frozen_string_literal: true

# == Schema Information
#
# Table name: price_lists
#
#  id                 :bigint           not null, primary key
#  name               :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  vending_machine_id :bigint           not null
#
# Indexes
#
#  index_price_lists_on_vending_machine_id  (vending_machine_id)
#
# Foreign Keys
#
#  fk_rails_...  (vending_machine_id => vending_machines.id)
#
class PriceList < ApplicationRecord
  has_many :price_list_items, dependent: :destroy
  has_many :products, through: :price_list_items
  has_many :vending_machines
end
