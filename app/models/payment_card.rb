# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_cards
#
#  id                   :bigint           not null, primary key
#  brand                :string
#  category             :string
#  default              :boolean          default(FALSE)
#  exp_month            :integer
#  exp_year             :integer
#  fingerprint          :string
#  first_eight          :string
#  first_six            :string
#  funding              :string
#  last_four            :string
#  name                 :string
#  scheme               :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  card_id              :string           not null
#  payment_agreement_id :string
#  payment_customer_id  :integer          not null
#
# Indexes
#
#  index_payment_cards_on_card_id              (card_id) UNIQUE
#  index_payment_cards_on_payment_customer_id  (payment_customer_id)
#
class PaymentCard < ApplicationRecord
  belongs_to :payment_customer, optional: false

  validates :card_id, presence: true, uniqueness: true
  validate :single_default_per_payment_customer

  private

  def single_default_per_payment_customer
    return unless default

    scope = PaymentCard.where(payment_customer_id: payment_customer_id, default: true)
    scope = scope.where.not(id: id) if persisted?

    return unless scope.exists?

    errors.add(:base, 'only one default card is allowed per customer')
  end
end
