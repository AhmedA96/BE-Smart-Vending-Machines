# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentCustomer, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:payment_cards) }
    it { should have_many(:payment_transactions) }
  end
  describe 'validations' do
    it { should validate_presence_of(:payment_customer_number) }
  end
end
