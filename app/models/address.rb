# frozen_string_literal: true

# == Schema Information
#
# Table name: addresses
#
#  id              :bigint           not null, primary key
#  address         :string
#  appart_number   :string           default("N/A"), not null
#  building_number :string           default("N/A"), not null
#  city            :string
#  default         :boolean          default(FALSE), not null
#  floor_number    :string           default("N/A"), not null
#  name            :string           default(""), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  country_id      :integer
#  user_id         :integer          not null
#
class Address < ApplicationRecord
  belongs_to :country
  belongs_to :user

  validates :name, presence: true
  validates :address, presence: true

  validates :appart_number, :building_number, :floor_number, presence: true
end
