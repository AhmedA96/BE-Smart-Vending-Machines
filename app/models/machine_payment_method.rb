# frozen_string_literal: true

# == Schema Information
#
# Table name: machine_payment_methods
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  machine_id        :integer
#  payment_method_id :integer
#
# Indexes
#
#  index_mach_pay_methods_on_machine_id_and_payment_method_id  (machine_id,payment_method_id) UNIQUE
#  index_machine_payment_methods_on_machine_id                 (machine_id)
#  index_machine_payment_methods_on_payment_method_id          (payment_method_id)
#
class MachinePaymentMethod < ApplicationRecord
  belongs_to :machine, optional: false
  belongs_to :payment_method, optional: false

  validates :machine_id, uniqueness: { scope: :payment_method_id }
end
