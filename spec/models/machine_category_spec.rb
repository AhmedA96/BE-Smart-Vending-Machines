# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MachineCategory, type: :model do
  describe 'associations' do
    it { should have_many(:vending_machines) }
  end

  describe 'validations' do
    subject { build(:machine_category) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end
end
