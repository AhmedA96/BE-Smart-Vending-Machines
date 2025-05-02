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
  acts_as_paranoid

  has_many_attached :images, dependent: :destroy

  has_many :variants, dependent: :destroy
  has_many :product_categories, dependent: :destroy
  has_many :categories, through: :product_categories

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

  scope :sort_by_price, lambda { |price_list_id, sort_direction|
    joins(variants: :price_list_items)
      .where(price_list_items: { price_list_id: price_list_id })
      .reorder(price_list_items: { price: sort_direction })
  }
  scope :with_stock_availability, lambda { |machine_id, min_quantity = 1|
    joins(variants: :machine_items)
      .where(machine_items: { machine_id: machine_id })
      .where(machine_items: { stock: min_quantity.. })
      .distinct
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

  scope :search, lambda { |term|
    return all if term.blank?

    term = "%#{sanitize_sql_like(term)}%"
    joins(:brand, :categories)
      .where(
        'products.name ILIKE :term OR brands.name ILIKE :term OR categories.name ILIKE :term',
        term: term
      ).distinct
  }

  def master
    variants.find_by(is_master: true)
  end
end
