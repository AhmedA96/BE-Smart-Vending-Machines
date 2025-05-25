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
    subject { build(:machine) }

    it { should validate_presence_of(:external_machine_id) }
    it { should validate_uniqueness_of(:external_machine_id) }

    it 'validates status inclusion' do
      should validate_inclusion_of(:status)
        .in_array(%w[Active Inactive Maintenance Retired])
        .allow_nil
    end
  end

  describe 'scopes' do
    let!(:active_machine) { create(:machine, status: 'Active') }
    let!(:inactive_machine) { create(:machine, status: 'Inactive') }

    describe '.active' do
      it 'returns only active machines' do
        expect(described_class.active).to include(active_machine)
        expect(described_class.active).not_to include(inactive_machine)
      end
    end
  end

  describe '.nearby' do
    let!(:close_machine) do
      create(:machine,
             status: 'Active',
             coordinates: 'POINT(100.5 13.7)')
    end

    let!(:far_machine) do
      create(:machine,
             status: 'Active',
             coordinates: 'POINT(104.5 15.7)')
    end

    it 'returns machines within specified radius' do
      result = described_class.nearby(
        latitude: 13.7,
        longitude: 100.5,
        radius_in_meters: 1000
      )

      expect(result).to include(close_machine)
      expect(result).not_to include(far_machine)
    end

    it 'orders results by distance' do
      create(:machine,
             status: 'Active',
             coordinates: 'POINT(100.51 13.71)')

      results = described_class.nearby(
        latitude: 13.7,
        longitude: 100.5,
        radius_in_meters: 5000
      )

      expect(results.first).to eq(close_machine)
    end
  end
end
