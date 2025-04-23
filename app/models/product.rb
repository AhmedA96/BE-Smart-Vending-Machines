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
#  slug                   :string
#  sorting                :integer          default(1)
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
#  index_products_on_sorting     (sorting)
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
  validates :sorting, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
end
