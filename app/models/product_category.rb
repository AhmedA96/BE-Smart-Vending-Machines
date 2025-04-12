# frozen_string_literal: true

# == Schema Information
#
# Table name: product_categories
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :bigint
#  product_id  :bigint
#
# Indexes
#
#  index_product_categories_on_category_id  (category_id)
#  index_product_categories_on_product_id   (product_id)
#  index_product_categories_uniqueness      (product_id,category_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (product_id => products.id)
#
class ProductCategory < ApplicationRecord
  belongs_to :product, optional: false
  belongs_to :category, optional: false

  validates :product_id, uniqueness: { scope: %i[category_id] }

  delegate :name, to: :category
end
