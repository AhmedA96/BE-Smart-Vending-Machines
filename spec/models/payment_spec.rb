# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'associations' do
    it { should belong_to(:order) }
    it { should belong_to(:payment_method) }
  end
  describe 'validations' do
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:status) }
  end
end
