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
  extend Mobility

  has_one_attached :image, dependent: :destroy

  translates :presentation, :description
  accepts_nested_attributes_for :translations, allow_destroy: true

  has_many :machine_payment_methods, dependent: :destroy
  has_many :payments, dependent: :nullify
  has_many :payment_method_translations, dependent: :destroy

  validates :name, presence: true

  scope :active_for_machine, lambda { |machine_id = nil|
    if machine_id
      joins(:machine_payment_methods)
        .where(active: true)
        .where(machine_payment_methods: { machine_id: machine_id, active: true })
        .distinct
    else
      where(active: true)
    end
  }
end
