# frozen_string_literal: true

# == Schema Information
#
# Table name: brands
#
#  id          :bigint           not null, primary key
#  background  :string
#  description :text
#  logo        :string
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Brand < ApplicationRecord
  extend Mobility

  translates :description, :presentation
  accepts_nested_attributes_for :translations

  has_one_attached :logo, dependent: :destroy
  has_one_attached :cover, dependent: :destroy

  has_many :products, dependent: :nullify
  has_many :product_categories, through: :products
  has_many :categories, -> { distinct }, through: :product_categories
  has_many :brand_translations, dependent: :destroy

  validates :name, presence: true

  scope :by_location, lambda { |location_id|
    joins(products: { variants: { machine_items: { machine: :location } } })
      .where(locations: { id: location_id })
      .distinct
  }
end
