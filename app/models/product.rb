# frozen_string_literal: true

# == Schema Information
#
# Table name: products
#
#  id          :bigint           not null, primary key
#  description :text
#  images      :jsonb
#  is_active   :boolean          default(TRUE)
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_products_on_is_active  (is_active)
#  index_products_on_name       (name)
#
class Product < ApplicationRecord
  has_many :machine_products, dependent: :destroy
  has_many :vending_machines, through: :machine_products

  validates :name, presence: true
  validates :images, presence: true

  scope :active, -> { where(is_active: true) }
end
