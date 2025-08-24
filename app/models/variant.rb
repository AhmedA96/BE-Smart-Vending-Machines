# frozen_string_literal: true

# == Schema Information
#
# Table name: variants
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE)
#  cost_price :decimal(10, 2)   default(0.0)
#  deleted_at :datetime
#  goods_uuid :string
#  is_master  :boolean          default(FALSE), not null
#  name       :string
#  points     :integer
#  position   :integer          default(1)
#  size       :string
#  sku        :string           not null
#  weight     :float            default(0.0)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :integer
#
# Indexes
#
#  index_variants_on_active        (active)
#  index_variants_on_created_at    (created_at)
#  index_variants_on_deleted_at    (deleted_at)
#  index_variants_on_goods_uuid    (goods_uuid) UNIQUE
#  index_variants_on_position      (position)
#  index_variants_on_product_id    (product_id)
#  index_variants_on_product_size  (product_id,size) UNIQUE
#  index_variants_on_size          (size)
#  index_variants_on_sku           (sku) UNIQUE
#
class Variant < ApplicationRecord
  extend Mobility

  acts_as_paranoid
  translates :presentation
  accepts_nested_attributes_for :translations

  delegate :name, to: :product, prefix: true
  delegate :max_orderable_quantity, to: :product

  validates :sku, presence: true
  validates :sku, uniqueness: { case_sensitive: false }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  belongs_to :product, optional: true

  has_many :machine_items, dependent: :destroy
  has_many :machines, through: :machine_items
  has_many :price_list_items
  has_many :price_lists, through: :price_list_items
  has_many :line_items, dependent: :destroy
  has_many :orders, through: :line_items
  has_many :variant_translations, dependent: :destroy

  scope :active, -> { where(active: true) }

  scope :available_in_machine_with_price_list, lambda { |machine|
    joins(:machine_items, :price_list_items)
      .where(machine_items: { machine_id: machine.id })
      .where(price_list_items: { price_list_id: machine.location&.price_list_id })
      .distinct
  }

  scope :filtered_by_category, lambda { |category_ids|
    joins(product: :categories)
      .where(categories: { id: category_ids })
  }

  scope :popular, lambda { |limit = 10|
    joins(:line_items)
      .group('variants.id')
      .order('COUNT(line_items.id) DESC')
      .limit(limit)
      .select('variants.*, COUNT(line_items.id) as total_orders')
  }

  scope :trending, lambda { |days = 7, limit = 10|
    joins(line_items: :order)
      .where(orders: { created_at: days.days.ago.. })
      .group('variants.id')
      .order('COUNT(line_items.id) DESC')
      .limit(limit)
      .select('variants.*, COUNT(line_items.id) as recent_orders')
  }

  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  def with_price_list(price_list_id)
    return unless price_list_id

    price_list_items.find_by(price_list_id:)
  end

  def machine_stock(machine)
    return unless machine&.id

    MachineItem
      .where(variant_id: id, machine_id: machine)
      .pick('machine_items.stock') || 0
  end

  def machine_available_stock(machine)
    return 0 unless machine&.id

    MachineItem
      .where(variant_id: id, machine_id: machine)
      .pick(Arel.sql('COALESCE(machine_items.stock,0) - COALESCE(machine_items.reserved_stock,0)')).to_i
  end

  def full_name
    "#{product.name} - #{name unless product&.name == name} [#{sku}]"
  end
end
