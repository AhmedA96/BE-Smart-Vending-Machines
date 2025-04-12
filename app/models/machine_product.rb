# frozen_string_literal: true

# == Schema Information
#
# Table name: machine_products
#
#  id                 :bigint           not null, primary key
#  stock              :integer          default(0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  product_id         :bigint           not null
#  variant_id         :bigint
#  vending_machine_id :bigint           not null
#
# Indexes
#
#  index_machine_products_on_product_id          (product_id)
#  index_machine_products_on_variant_id          (variant_id)
#  index_machine_products_on_vending_machine_id  (vending_machine_id)
#  index_machine_products_on_vm_product_variant  (vending_machine_id,product_id,variant_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#  fk_rails_...  (variant_id => variants.id)
#  fk_rails_...  (vending_machine_id => vending_machines.id)
#
class MachineProduct < ApplicationRecord
  belongs_to :product, -> { with_deleted }, inverse_of: :machine_products
  belongs_to :vending_machine
  belongs_to :variant, optional: true

  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: { scope: %i[vending_machine_id variant_id] }
end
