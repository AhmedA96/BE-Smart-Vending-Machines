# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_statuses
#
#  id                     :bigint           not null, primary key
#  status                 :string           not null
#  transaction_created_at :datetime
#  transaction_url        :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  payment_transaction_id :integer
#
class PaymentStatus < ApplicationRecord
  belongs_to :payment_transaction, optional: false
  delegate :payment, to: :payment_transaction

  validates :status, presence: true

  after_create_commit :complete_payment

  def complete_payment
    return unless status == 'CAPTURED'

    payment.complete!
  end
end
