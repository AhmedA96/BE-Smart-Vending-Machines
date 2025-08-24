# frozen_string_literal: true

# == Schema Information
#
# Table name: products
#
#  id                     :bigint           not null, primary key
#  deleted_at             :datetime
#  description            :string
#  max_orderable_quantity :integer
#  name                   :string           not null
#  position               :integer          default(1)
#  presentation           :string
#  slug                   :string
#  status                 :string
#  total_rate             :float
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  brand_id               :bigint
#
# Indexes
#
#  index_products_on_brand_id    (brand_id)
#  index_products_on_created_at  (created_at)
#  index_products_on_deleted_at  (deleted_at)
#  index_products_on_name        (name)
#  index_products_on_position    (position)
#
# Foreign Keys
#
#  fk_rails_...  (brand_id => brands.id)
#
class Product < ApplicationRecord
  extend Mobility

  acts_as_paranoid
  translates :presentation, :description
  accepts_nested_attributes_for :translations

  has_many_attached :images, dependent: :destroy

  has_many :variants, dependent: :destroy
  has_many :line_items, through: :variants
  has_many :orders, through: :line_items

  has_many :product_categories, dependent: :destroy
  has_many :categories, through: :product_categories
  has_many :product_translations, dependent: :destroy
  has_many :user_favorites, dependent: :destroy
  has_many :users_who_favorited, through: :user_favorites, source: :user

  belongs_to :brand, optional: true

  validates :name, :slug, presence: true
  validates :status, presence: true, inclusion: { in: %w[Active Inactive] }
  validates :max_orderable_quantity, numericality: { greater_than: 0, allow_nil: true }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  scope :filtered_by_machine, lambda { |machine_id|
    joins(variants: :machine_items)
      .where(machine_items: { machine_id: machine_id })
      .includes(:variants)
      .distinct
      .order_by_position
  }

  scope :with_priced_variants_for_machine, lambda { |machine|
    joins(variants: %i[machine_items price_list_items])
      .where(machine_items: { machine_id: machine.id })
      .where(price_list_items: { price_list_id: machine.location&.price_list_id })
      .includes(:variants)
      .distinct
      .order_by_position
  }

  scope :order_by_position, -> { order(position: :asc) }

  scope :by_category, lambda { |category_id|
    return all if category_id.blank?

    joins(:product_categories).where(product_categories: { category_id: }).order_by_position.distinct
  }

  scope :by_price_range_for_price_list, lambda { |price_list_id, min_price, max_price|
    joins(variants: :price_list_items)
      .where(price_list_items: { price_list_id: })
      .where(price_list_items: { price: min_price..max_price })
  }

  scope :sort_by_price, lambda { |sort_direction|
    joins(variants: :price_list_items)
      .reorder(price_list_items: { price: sort_direction })
  }

  scope :with_stock_availability, lambda { |machine, quantity|
    joins(variants: :machine_items)
      .where(machine_items: { machine_id: machine.id })
      .where('(COALESCE(machine_items.stock,0) - COALESCE(machine_items.reserved_stock,0)) > ?', quantity)
  }

  scope :alternatives, lambda { |category_id, product_id|
    joins(:product_categories)
      .where(product_categories: { category_id: category_id })
      .where.not(id: product_id)
      .joins(:variants)
      .order_by_position
      .distinct
  }

  scope :with_price_list, lambda { |price_list_id|
    joins(variants: :price_list_items).where(price_list_items: { price_list_id: })
  }

  scope :active, -> { where(status: 'Active') }

  def master
    variants.find_by(is_master: true)
  end

  def order_count_for_user(user)
    line_items.joins(:order).where(orders: { user_id: user.id }).count
  end

  def last_ordered_by_user(user)
    orders.where(user_id: user.id).order(created_at: :desc).first&.created_at
  end
end
