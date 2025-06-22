# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Machine, type: :model do
  describe 'associations' do
    it { should belong_to(:vendor) }
    it { should belong_to(:category).class_name('MachineCategory') }
    it { should belong_to(:location) }
    it { should belong_to(:supplier) }
    it { should belong_to(:country) }
    it { should have_one(:price_list).through(:location) }
    it { should have_many(:machine_statuses) }
    it { should have_many(:machine_items) }
    it { should have_many(:variants).through(:machine_items) }
    it { should have_many(:machine_translations) }
    it { should have_many(:machine_payment_methods) }
    it { should have_many(:payment_methods).through(:machine_payment_methods) }
  end

  describe 'validations' do
    subject { machines(:machine_001) } # rubocop:disable Naming/VariableNumber

    it { should validate_presence_of(:external_machine_id) }
    it { should validate_uniqueness_of(:external_machine_id) }

    it 'validates status inclusion' do
      should validate_inclusion_of(:status)
        .in_array(%w[Active Inactive Maintenance Retired])
        .allow_nil
    end
  end

  describe 'scopes' do
    let(:active_machine) { machines(:machine_001) } # rubocop:disable Naming/VariableNumber
    let(:inactive_machine) { machines(:machine_002) } # rubocop:disable Naming/VariableNumber

    describe '.active' do
      it 'returns only active machines' do
        expect(described_class.active).to include(active_machine)
        expect(described_class.active).not_to include(inactive_machine)
      end
    end
  end
  describe '.nearby' do
    let(:reference_lat) { 40.7484 }
    let(:reference_lng) { -73.9857 }

    let(:close_machine) { machines(:machine_001) } # rubocop:disable Naming/VariableNumber
    let(:far_machine)   { machines(:machine_002) } # rubocop:disable Naming/VariableNumber

    it 'returns machines within specified radius' do
      result = described_class.nearby(
        latitude: reference_lat,
        longitude: reference_lng,
        radius_in_meters: 1000
      )

      expect(result).to include(close_machine)
      expect(result).not_to include(far_machine)
    end

    it 'orders results by distance' do
      result = described_class.nearby(
        latitude: reference_lat,
        longitude: reference_lng,
        radius_in_meters: 10_000_000
      )

      expect(result.first).to eq(close_machine)
    end
  end
end
