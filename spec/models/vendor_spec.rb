# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Vendor, type: :model do
  describe 'associations' do
    it { should have_many(:machines) }
  end

  describe 'validations' do
    subject { build(:vendor) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:address).is_at_most(255) }
    it { should allow_value('test@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
  end
end
