# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentTransaction, type: :model do
  describe 'associations' do
    it { should belong_to(:payment_customer) }
    it { should have_many(:payment_statuses).dependent(:destroy) }
  end
  describe 'validations' do
    it { should validate_presence_of(:charge_id) }
  end
end
