# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_methods
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(TRUE), not null
#  description  :string
#  name         :string           not null
#  presentation :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class PaymentMethod < ApplicationRecord
  has_many :machine_payment_methods, dependent: :destroy

  validates :name, presence: true, inclusion: { in: PAYMENT_METHODS.values }

  scope :active_for_machine, lambda {
    joins(:machine_payment_methods)
      .where(active: true)
      .where(machine_payment_methods: { active: true })
  }
end
