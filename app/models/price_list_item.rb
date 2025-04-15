# frozen_string_literal: true

# == Schema Information
#
# Table name: price_list_items
#
#  id            :bigint           not null, primary key
#  price         :decimal(10, 2)   not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  price_list_id :bigint           not null
#  product_id    :bigint           not null
#
# Indexes
#
#  index_price_list_items_on_price_list_id  (price_list_id)
#  index_price_list_items_on_product_id     (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (price_list_id => price_lists.id)
#  fk_rails_...  (product_id => products.id)
#
class PriceListItem < ApplicationRecord
  belongs_to :price_list, optional: false
  belongs_to :variant
  belongs_to :product

  validates :price, presence: true, numericality: { greater_than: 0 }
end
