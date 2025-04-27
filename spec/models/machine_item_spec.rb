# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MachineItem, type: :model do
  describe 'associations' do
    it { should belong_to(:variant) }
    it { should belong_to(:machine) }
    it { should have_one(:product).through(:variant) }
  end

  describe 'validations' do
    subject { build(:machine_item) }

    it { should validate_presence_of(:stock) }
    it { should validate_numericality_of(:stock).only_integer.is_greater_than_or_equal_to(0) }

    it 'validates uniqueness of variant_id scoped to machine_id' do
      create(:machine_item)
      should validate_uniqueness_of(:variant_id).scoped_to(:machine_id)
    end
  end
end
