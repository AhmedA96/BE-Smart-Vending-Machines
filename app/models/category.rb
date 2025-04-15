# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id                 :bigint           not null, primary key
#  active             :boolean          default(TRUE), not null
#  name               :string
#  position           :integer          default(0)
#  presentation       :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  parent_category_id :bigint
#
# Indexes
#
#  index_categories_on_parent_category_id  (parent_category_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_category_id => categories.id)
#
class Category < ApplicationRecord
  belongs_to :parent_category, class_name: 'Category', optional: true, inverse_of: :subcategories
  has_many :subcategories, class_name: 'Category', foreign_key: :parent_category_id, dependent: :destroy,
                           inverse_of: :parent_category

  has_many :product_categories, dependent: :destroy
  has_many :products, through: :product_categories

  validates :name, :presentation, presence: true
end
