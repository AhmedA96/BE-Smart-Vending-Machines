# frozen_string_literal: true

# == Schema Information
#
# Table name: line_items
#
#  id                   :bigint           not null, primary key
#  buyx_gety_discount   :decimal(10, 2)
#  price                :decimal(10, 2)   default(0.0)
#  price_after_discount :decimal(10, 2)
#  processed            :boolean          default(FALSE), not null
#  quantity             :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  order_id             :bigint
#  variant_id           :bigint
#
# Indexes
#
#  index_line_items_on_order_id                 (order_id)
#  index_line_items_on_variant_id               (variant_id)
#  index_line_items_on_variant_id_and_order_id  (variant_id,order_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#  fk_rails_...  (variant_id => variants.id)
#
class LineItem < ApplicationRecord
  belongs_to :order
  belongs_to :variant, optional: false

  validates :quantity, presence: true
end
