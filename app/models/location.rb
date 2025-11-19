# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id            :bigint           not null, primary key
#  address       :string
#  city          :string
#  coordinates   :geography        point, 4326
#  landmark      :string
#  name          :string
#  presentation  :string
#  state         :string
#  zip_code      :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  country_id    :bigint
#  price_list_id :bigint
#
# Indexes
#
#  index_locations_on_coordinates    (coordinates) USING gist
#  index_locations_on_country_id     (country_id)
#  index_locations_on_price_list_id  (price_list_id)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#  fk_rails_...  (price_list_id => price_lists.id)
#
class Location < ApplicationRecord
  extend Mobility

  translates :presentation
  accepts_nested_attributes_for :translations

  belongs_to :price_list
  belongs_to :country

  has_many :machines
  has_many :location_translations, dependent: :destroy

  def self.nearby(latitude:, longitude:, radius_km: nil)
    point_sql = 'ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)'
    distance_sql = "ST_Distance(coordinates, #{point_sql})"

    base_binds = { latitude: latitude, longitude: longitude }

    query = select(Arel.sql(ActiveRecord::Base.sanitize_sql_array(["*, #{distance_sql} as distance", base_binds])))
            .where.not(coordinates: nil)

    if radius_km
      radius_meters = radius_km.to_f * 1000
      radius_binds = base_binds.merge(radius: radius_meters)

      query = query.where(
        Arel.sql(ActiveRecord::Base.sanitize_sql_array([
                                                         "ST_DWithin(coordinates, #{point_sql}, :radius)", radius_binds
                                                       ]))
      )
    end

    query.order(:distance)
  end
end
