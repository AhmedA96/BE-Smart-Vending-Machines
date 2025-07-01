# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(TRUE), not null
#  name         :string
#  position     :integer          default(0)
#  presentation :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Category < ApplicationRecord
  extend Mobility
  translates :presentation, :description

  has_many :product_categories, dependent: :destroy
  has_many :products, through: :product_categories
  has_many :category_translations, dependent: :destroy
  has_many :brands, -> { distinct }, through: :products

  accepts_nested_attributes_for :translations

  validates :name, :presentation, presence: true

  def self.with_brands
    includes(:brands).map do |category|
      {
        id: category.id,
        name: category.name,
        brands: category.brands.map { |brand| { id: brand.id, name: brand.name } }
      }
    end
  end
end
