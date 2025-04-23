# frozen_string_literal: true

# == Schema Information
#
# Table name: machine_items
#
#  id                 :bigint           not null, primary key
#  line_number        :integer
#  stock              :integer          default(0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  variant_id         :bigint           not null
#  vending_machine_id :bigint           not null
#
# Indexes
#
#  index_machine_items_on_variant_id                         (variant_id)
#  index_machine_items_on_vending_machine_id                 (vending_machine_id)
#  index_machine_items_on_vending_machine_id_and_variant_id  (vending_machine_id,variant_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (variant_id => variants.id)
#  fk_rails_...  (vending_machine_id => vending_machines.id)
#
class MachineItem < ApplicationRecord
  belongs_to :vending_machine
  belongs_to :variant
  has_one :product, through: :variant

  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  # This validation is backed by a unique index on (vending_machine_id, variant_id)
  validates :variant_id, uniqueness: { scope: :vending_machine_id }
end
