# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id            :bigint           not null, primary key
#  address       :string
#  city          :string
#  landmark      :string
#  name          :string
#  state         :string
#  zip_code      :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  price_list_id :bigint
#
# Indexes
#
#  index_locations_on_price_list_id  (price_list_id)
#
# Foreign Keys
#
#  fk_rails_...  (price_list_id => price_lists.id)
#
class Location < ApplicationRecord
  extend Mobility
  translates :name

  belongs_to :price_list
  has_many :machines
  has_many :location_translations, dependent: :destroy
end
