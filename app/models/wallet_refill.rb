# frozen_string_literal: true

# == Schema Information
#
# Table name: wallet_refills
#
#  id                :bigint           not null, primary key
#  amount            :decimal(10, 2)   not null
#  status            :string           default("pending")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  card_id           :integer
#  payment_method_id :integer
#  token_id          :string
#  wallet_id         :bigint           not null
#
# Indexes
#
#  index_wallet_refills_on_wallet_id  (wallet_id)
#
# Foreign Keys
#
#  fk_rails_...  (wallet_id => wallets.id)
#
class WalletRefill < ApplicationRecord
  include AASM

  VALID_TOP_UP_AMOUNTS = [25, 50, 100].freeze

  belongs_to :wallet, optional: false
  belongs_to :payment_method, optional: false

  validates :amount, presence: true, inclusion: { in: VALID_TOP_UP_AMOUNTS }
  validates :status, presence: true

  aasm column: 'status', whiny_transitions: false do
    state :pending, initial: true
    state :failed
    state :completed

    def en_currency
      wallet.user.country.country_translations.find_by(locale: 'en')&.currency
    end
  end
end
