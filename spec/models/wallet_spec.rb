# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wallet, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:wallet_transactions) }
    it { should have_many(:wallet_refills) }
  end

  describe 'validations' do
    it { should validate_presence_of(:balance) }
    it { should validate_numericality_of(:balance).is_greater_than_or_equal_to(0) }
  end
end
