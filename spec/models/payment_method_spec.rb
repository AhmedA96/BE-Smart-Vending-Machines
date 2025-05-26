# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentMethod, type: :model do
  describe 'associations' do
    it { should have_many(:machine_payment_methods) }
    it { should have_many(:payments) }
  end
  describe 'validations' do
    it { should validate_presence_of(:name) }
  end
end
