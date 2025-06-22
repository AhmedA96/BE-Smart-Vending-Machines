# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentStatus, type: :model do
  describe 'associations' do
    it { should belong_to(:payment_transaction) }
  end

  describe 'validations' do
    it { should validate_presence_of(:status) }
  end
end
