# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentCard, type: :model do
  describe 'associations' do
    it { should belong_to(:payment_customer) }
  end

  describe 'validations' do
    it { should validate_presence_of(:card_id) }
  end
end
