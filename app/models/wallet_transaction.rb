# frozen_string_literal: true

# == Schema Information
#
# Table name: wallet_transactions
#
#  id               :bigint           not null, primary key
#  amount           :decimal(15, 2)   not null
#  description      :string
#  transaction_type :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  wallet_id        :bigint           not null
#
# Indexes
#
#  index_wallet_transactions_on_wallet_id  (wallet_id)
#
# Foreign Keys
#
#  fk_rails_...  (wallet_id => wallets.id)
#
class WalletTransaction < ApplicationRecord
  belongs_to :wallet

  TYPES = %w[top_up purchase].freeze

  validates :amount, numericality: { greater_than: 0 }
  validates :transaction_type, inclusion: { in: TYPES }

  scope :top_ups, -> { where(transaction_type: 'top_up') }
  scope :purchases, -> { where(transaction_type: 'purchase') }
  scope :recent, -> { order(created_at: :desc) }
end
