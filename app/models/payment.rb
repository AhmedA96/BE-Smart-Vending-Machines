# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id                :bigint           not null, primary key
#  amount            :decimal(10, 2)   not null
#  deleted_at        :datetime
#  message           :string
#  status            :string           default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  card_id           :integer
#  order_id          :integer
#  payment_method_id :integer
#  token_id          :string
#
class Payment < ApplicationRecord
  include AASM
  acts_as_paranoid

  belongs_to :order, optional: false
  belongs_to :payment_method, optional: false

  validates :amount, presence: true
  validates :status, presence: true

  aasm column: 'status', whiny_transitions: false do
    state :pending, initial: true
    state :completed
    state :failed
    state :refunded
    state :partially_refunded

    event :complete do
      transitions from: :pending, to: :completed
    end

    event :failed do
      transitions from: :pending, to: :failed
    end
  end
end
