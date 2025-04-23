# frozen_string_literal: true

# == Schema Information
#
# Table name: vending_machines
#
#  id                  :bigint           not null, primary key
#  coordinates         :geography        point, 4326
#  installed_at        :datetime
#  last_service_date   :datetime
#  location_updated_at :datetime
#  name                :string
#  status              :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  category_id         :bigint           not null
#  location_id         :bigint
#  manufacturer_id     :string
#  vendor_id           :bigint           not null
#
# Indexes
#
#  index_vending_machines_on_category_id      (category_id)
#  index_vending_machines_on_coordinates      (coordinates) USING gist
#  index_vending_machines_on_location_id      (location_id)
#  index_vending_machines_on_manufacturer_id  (manufacturer_id) UNIQUE
#  index_vending_machines_on_vendor_id        (vendor_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => machine_categories.id)
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (vendor_id => vendors.id)
#
class VendingMachine < ApplicationRecord
  belongs_to :vendor
  belongs_to :category, class_name: 'MachineCategory'
  belongs_to :location

  has_one :price_list, through: :location

  has_many :machine_statuses
  has_many :machine_items
  has_many :variants, through: :machine_items

  validates :manufacturer_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[Active Inactive Maintenance Retired] }, allow_nil: true

  scope :active, -> { where(status: 'Active') }

  def self.nearby(latitude:, longitude:, radius_in_meters: 5000)
    point_sql = 'ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)'
    distance_sql = "ST_Distance(coordinates, #{point_sql})"
    within_sql = "ST_DWithin(coordinates, #{point_sql}, :radius)"

    binds = { latitude: latitude, longitude: longitude, radius: radius_in_meters }

    active
      .where(ActiveRecord::Base.sanitize_sql_array([within_sql, binds]))
      .select(Arel.sql(ActiveRecord::Base.sanitize_sql_array(["*, #{distance_sql} as distance", binds])))
      .order('distance ASC')
  end
end
