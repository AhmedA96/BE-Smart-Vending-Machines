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

  validates :quantity, presence: true, numericality: { greater_than: 0 }

  validate :variant_available_for_machine
  validate :sufficient_stock, on: %i[create update]
  validate :within_machine_item_limit, on: %i[create update]

  def price_list
    order.machine.price_list
  end

  private

  def variant_available_for_machine
    return unless order&.machine && variant

    return if order.machine.machine_items.exists?(variant: variant)

    errors.add(:base, I18n.t('errors.orders.variant_not_available_for_machine'))
  end

  def within_machine_item_limit
    return unless order&.machine&.max_items_per_order

    current_total = order.line_items.where.not(id: id).sum(:quantity)
    new_total = current_total + quantity.to_i

    return unless new_total > order.machine.max_items_per_order

    errors.add(:base,
               I18n.t('errors.orders.exceeds_machine_max_items_limit', count: order.machine.max_items_per_order))
  end

  def sufficient_stock
    return unless order&.machine &&
                  variant &&
                  quantity &&
                  order.machine.machine_items.exists?(variant: variant)

    stock = available_quantity
    return if stock >= quantity.to_i

    errors.add(:base,
               I18n.t('errors.orders.required_quantity_is_not_available_in_the_machine', product_name: variant.name))
  end

  def available_quantity
    Variant.find(variant_id).machine_available_stock(order.machine)
  end
end
