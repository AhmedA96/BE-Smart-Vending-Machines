# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WalletTransaction, type: :model do
  let(:wallet) { wallets(:one) }

  describe 'associations' do
    it { should belong_to(:wallet) }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      tx = WalletTransaction.new(wallet: wallet, amount: 100.0, transaction_type: 'top_up')
      expect(tx).to be_valid
    end

    it 'is invalid with non-positive amount' do
      tx = WalletTransaction.new(wallet: wallet, amount: 0, transaction_type: 'top_up')
      expect(tx).not_to be_valid
    end

    it 'is invalid with unsupported transaction_type' do
      tx = WalletTransaction.new(wallet: wallet, amount: 50, transaction_type: 'refund')
      expect(tx).not_to be_valid
    end
  end

  describe 'callbacks' do
    it 'updates wallet balance on top_up' do
      initial_balance = wallet.balance
      WalletTransaction.create!(wallet: wallet, amount: 50, transaction_type: 'top_up')
      expect(wallet.reload.balance).to eq(initial_balance + 50)
    end

    it 'does not update wallet balance on purchase' do
      initial_balance = wallet.balance
      WalletTransaction.create!(wallet: wallet, amount: 30, transaction_type: 'purchase')
      expect(wallet.reload.balance).to eq(initial_balance)
    end
  end

  describe 'scopes' do
    it 'returns only top_up transactions' do
      top_ups = WalletTransaction.top_ups
      expect(top_ups.pluck(:transaction_type).uniq).to eq(['top_up'])
    end

    it 'returns only purchase transactions' do
      purchases = WalletTransaction.purchases
      expect(purchases.pluck(:transaction_type).uniq).to eq(['purchase'])
    end

    it 'orders transactions by most recent first' do
      tx = WalletTransaction.create!(wallet: wallet, amount: 10, transaction_type: 'top_up')
      expect(WalletTransaction.recent.first).to eq(tx)
    end
  end
end
