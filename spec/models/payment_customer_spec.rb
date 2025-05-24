# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentCustomer, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end
  describe 'validations' do
    it { should validate_presence_of(:payment_customer_number) }
  end
end
