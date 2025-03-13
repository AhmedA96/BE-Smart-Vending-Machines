# frozen_string_literal: true

class VendingMachine < ApplicationRecord
  belongs_to :vendor
  belongs_to :category, class_name: 'MachineCategory'
  has_many :machine_statuses

  validates :manufacturer_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[active inactive maintenance retired] }, allow_nil: true
end
