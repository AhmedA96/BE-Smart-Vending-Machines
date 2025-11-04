# frozen_string_literal: true

# == Schema Information
#
# Table name: machines
#
#  id                  :bigint           not null, primary key
#  coordinates         :geography        point, 4326
#  floor_no            :integer
#  installed_at        :datetime
#  last_service_date   :datetime
#  location_updated_at :datetime
#  machineuuid         :string
#  max_items_per_order :integer
#  name                :string
#  status              :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  category_id         :bigint           not null
#  location_id         :bigint
#  machine_type_id     :bigint
#  supplier_id         :bigint
#  vendor_id           :bigint           not null
#
# Indexes
#
#  index_machines_on_category_id      (category_id)
#  index_machines_on_coordinates      (coordinates) USING gist
#  index_machines_on_location_id      (location_id)
#  index_machines_on_machine_type_id  (machine_type_id)
#  index_machines_on_machineuuid      (machineuuid) UNIQUE
#  index_machines_on_supplier_id      (supplier_id)
#  index_machines_on_vendor_id        (vendor_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (machine_type_id => machine_types.id)
#  fk_rails_...  (supplier_id => suppliers.id)
#  fk_rails_...  (vendor_id => vendors.id)
#
class Machine < ApplicationRecord
  extend Mobility

  translates :name
  accepts_nested_attributes_for :translations

  belongs_to :vendor
  belongs_to :category, class_name: 'MachineCategory'
  belongs_to :location, optional: false
  belongs_to :supplier, optional: false
  belongs_to :machine_type

  has_one :price_list, through: :location
  has_one :country, through: :location

  has_many :machine_statuses
  has_many :machine_items
  has_many :variants, through: :machine_items
  has_many :machine_translations, dependent: :destroy
  has_many :machine_payment_methods, dependent: :destroy
  has_many :payment_methods, through: :machine_payment_methods
  has_many :orders, dependent: :nullify

  has_one_attached :image

  validates :machineuuid, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[Active Inactive Maintenance Retired] }, allow_nil: true

  delegate :capacity, to: :machine_type

  after_create :sync_machine_coordinates

  scope :by_supplier, ->(supplier) { where(supplier_id: supplier.id) }

  scope :active, -> { where(status: 'Active') }

  scope :stocked, lambda {
    joins(machine_items: :variant)
      .where(variants: { active: true })
      .where('(COALESCE(machine_items.stock,0) - COALESCE(machine_items.reserved_stock,0)) > 0')
      .distinct
  }

  def self.nearby(latitude:, longitude:, radius_in_meters: 5000)
    point_sql = 'ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)'
    distance_sql = "ST_Distance(coordinates, #{point_sql})"
    binds = { latitude: latitude, longitude: longitude, radius: radius_in_meters }

    query = active.select(
      Arel.sql(ActiveRecord::Base.sanitize_sql_array(["*, #{distance_sql} as distance", binds]))
    ).order(:distance)

    if Rails.env.production?
      within_sql = "ST_DWithin(coordinates, #{point_sql}, :radius)"
      query = query.where(ActiveRecord::Base.sanitize_sql_array([within_sql, binds]))
    end

    query
  end

  def active?
    status == 'Active'
  end

  def stocked?
    machine_items.joins(:variant)
                 .where(variants: { active: true })
                 .where('(COALESCE(machine_items.stock,0) - COALESCE(machine_items.reserved_stock,0)) > 0')
                 .exists?
  end

  def stock_indicator
    stocked? ? 'Stocked' : 'Empty'
  end

  def sync_machine_coordinates
    return unless supplier&.name&.downcase == 'vendlife'

    service = Suppliers::VendlifeService.new(supplier)
    service.sync_machine_data(self)
  rescue StandardError => e
    Rails.logger.error "Failed to sync coordinates for machine #{machineuuid}: #{e.message}"
  end
end
