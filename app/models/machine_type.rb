# frozen_string_literal: true

# == Schema Information
#
# Table name: machine_types
#
#  id                      :bigint           not null, primary key
#  capacity                :integer          not null
#  has_temperature_control :boolean          default(FALSE)
#  name                    :string           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_machine_types_on_name  (name) UNIQUE
#
class MachineType < ApplicationRecord
  has_many :machines

  validates :name, presence: true, uniqueness: true
  validates :capacity, presence: true, numericality: { greater_than: 0 } # capacity = total number of slots/machine
end
