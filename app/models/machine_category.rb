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
  translates :description, :presentation
  accepts_nested_attributes_for :translations

  has_many :machines, foreign_key: 'category_id', inverse_of: :category
  has_many :machine_category_translations, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2, maximum: 255 }
  validates :description, length: { maximum: 500 }, allow_blank: true
end
