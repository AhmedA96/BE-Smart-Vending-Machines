# frozen_string_literal: true

# == Schema Information
#
# Table name: variants
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE)
#  cost_price :decimal(10, 2)   default(0.0)
#  deleted_at :datetime
#  is_master  :boolean          default(FALSE), not null
#  name       :string
#  points     :integer
#  position   :integer          default(1)
#  sku        :string           not null
#  weight     :float            default(0.0)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :integer          not null
#
# Indexes
#
#  index_variants_on_active      (active)
#  index_variants_on_created_at  (created_at)
#  index_variants_on_deleted_at  (deleted_at)
#  index_variants_on_position    (position)
#  index_variants_on_product_id  (product_id)
#  index_variants_on_sku         (sku) UNIQUE
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

  belongs_to :product, optional: false

  has_many :machine_items
  has_many :machines, through: :machine_items
  has_many :price_list_items
  has_many :price_lists, through: :price_list_items
  has_many :line_items, dependent: :nullify
  has_many :variant_translations, dependent: :destroy

  def full_name
    "#{product.name} - #{product&.name == name ? '' : name} [#{sku}]"
  end
end
