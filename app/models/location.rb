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
#  state         :string
#  zip_code      :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  price_list_id :bigint
#
# Indexes
#
#  index_locations_on_coordinates    (coordinates) USING gist
#  index_locations_on_price_list_id  (price_list_id)
#
# Foreign Keys
#
#  fk_rails_...  (price_list_id => price_lists.id)
#
class Location < ApplicationRecord
  extend Mobility
  translates :name
  accepts_nested_attributes_for :translations

  belongs_to :price_list
  has_many :machines
  has_many :location_translations, dependent: :destroy

  def self.nearby(latitude:, longitude:, radius_km: nil)
    point_sql = 'ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)'
    distance_sql = "ST_Distance(coordinates, #{point_sql})"
    binds = { latitude: latitude, longitude: longitude }

    query = select(Arel.sql(ActiveRecord::Base.sanitize_sql_array(["*, #{distance_sql} as distance", binds])))
            .where.not(coordinates: nil)

    if radius_km
      radius_meters = radius_km * 1000
      binds[:radius] = radius_meters
      query = query.where(
        Arel.sql(ActiveRecord::Base.sanitize_sql_array([
                                                         "ST_DWithin(coordinates, #{point_sql}, :radius)",
                                                         binds
                                                       ]))
      )
    end

    query.order('distance DESC')
  end
end
