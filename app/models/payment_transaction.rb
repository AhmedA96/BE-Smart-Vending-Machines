# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_transactions
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  charge_id           :string           not null
#  payment_customer_id :integer
#  payment_id          :integer
#
# Indexes
#
#  index_payment_transactions_on_charge_id            (charge_id)
#  index_payment_transactions_on_payment_customer_id  (payment_customer_id)
#  index_payment_transactions_on_payment_id           (payment_id)
#
class PaymentTransaction < ApplicationRecord
  belongs_to :payment_customer, optional: false
  belongs_to :payment, optional: false

  has_many :payment_statuses, dependent: :destroy

  validates :charge_id, presence: true
end
