# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentStatus, type: :model do
  describe 'associations' do
    it { should belong_to(:payment_transaction) }

    it 'delegates payment to payment_transaction' do
      payment_status = payment_statuses(:pending_status)
      expect(payment_status.payment).to eq(payment_status.payment_transaction.payment)
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:status) }
  end

  describe 'callbacks' do
    let(:payment) { payments(:credit_card_payment) }
    let(:transaction) { payment_transactions(:txn_one) }

    it 'completes the payment if status is CAPTURED' do
      PaymentStatus.create!(status: 'CAPTURED', payment_transaction: transaction)
      payment.reload

      expect(payment).to be_completed
    end

    it 'does not complete the payment if status is not CAPTURED' do
      PaymentStatus.create!(status: 'FAILED', payment_transaction: transaction)
      payment.reload

      expect(payment).to be_pending
    end
  end
end
