# rubocop:disable Naming/VariableNumber
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MachineCategory, type: :model do
  describe 'associations' do
    it { should have_many(:machines) }
    it { should have_many(:machine_category_translations) }
  end

  describe 'validations' do
    subject { machine_categories(:snack_machines) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(500) }
  end

  describe 'scopes' do
    let(:machine1) { machines(:machine_001) }
    let(:machine2) { machines(:machine_002) }

    it '.for_machines returns categories linked to given machines' do
      category = machine1.category
      result = described_class.for_machines([machine1.id])

      expect(result).to include(category)
      expect(result).not_to include(machine2.category) if machine2.category != category
    end

    it '.for_nearby_machines returns categories for nearby machines' do
      result = described_class.for_nearby_machines(
        latitude: 30.0444, longitude: 31.2357
      )
      expect(result).to all(be_a(MachineCategory))
    end
  end
end

# rubocop:enable Naming/VariableNumber
