# frozen_string_literal: true

# == Schema Information
#
# Table name: countries
#
#  id             :bigint           not null, primary key
#  currency       :string
#  iso2           :string
#  name           :string
#  time_zone      :string
#  vat_percentage :decimal(10, 2)   default(0.0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Country < ApplicationRecord
  extend Mobility

  translates :presentation, :currency
  accepts_nested_attributes_for :translations

  has_many :locations
  has_many :machines, through: :locations
  has_many :country_translations, dependent: :destroy
  has_many :addresses, dependent: :destroy

  enum :name,
       { UAE: 'uae', KSA: 'saudi' }
  enum :currency, CURRENCIES.index_by(&:itself)

  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }, allow_nil: true
  validates :name, :iso2, :currency, presence: true
end
