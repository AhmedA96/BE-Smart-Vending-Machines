# frozen_string_literal: true

# == Schema Information
#
# Table name: machine_categories
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class MachineCategory < ApplicationRecord
  extend Mobility
  has_one_attached :logo, dependent: :destroy

  translates :description, :presentation
  accepts_nested_attributes_for :translations

  has_many :machines, foreign_key: 'category_id', inverse_of: :category
  has_many :machine_category_translations, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2, maximum: 255 }
  validates :description, length: { maximum: 500 }, allow_blank: true

  # returns distinct machines categories for only active machines with a given location id
  scope :by_location, lambda { |location_id|
    joins(:machines).where(machines: { location_id: location_id })
                    .merge(Machine.active)
                    .distinct
  }
end
