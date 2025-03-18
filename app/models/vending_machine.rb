# frozen_string_literal: true

# == Schema Information
#
# Table name: vending_machines
#
#  id                  :bigint           not null, primary key
#  installed_at        :datetime
#  last_service_date   :datetime
#  location            :geography        point, 4326
#  location_name       :string
#  location_updated_at :datetime
#  name                :string
#  status              :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  category_id         :bigint           not null
#  manufacturer_id     :string
#  vendor_id           :bigint           not null
#
# Indexes
#
#  index_vending_machines_on_category_id      (category_id)
#  index_vending_machines_on_location         (location) USING gist
#  index_vending_machines_on_manufacturer_id  (manufacturer_id) UNIQUE
#  index_vending_machines_on_vendor_id        (vendor_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => machine_categories.id)
#  fk_rails_...  (vendor_id => vendors.id)
#
class VendingMachine < ApplicationRecord
  belongs_to :vendor
  belongs_to :category, class_name: 'MachineCategory'
  has_many :machine_statuses

  validates :manufacturer_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[active inactive maintenance retired] }, allow_nil: true
end
