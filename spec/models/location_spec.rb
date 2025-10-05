# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'associations' do
    it { should belong_to(:price_list).optional(false) }
    it { should belong_to(:country).optional(false) }
    it { should have_many(:machines) }
    it { should have_many(:location_translations).dependent(:destroy) }
  end

  describe '.nearby' do
    let(:dubai_coords) { [25.2048, 55.2708] }
    let(:sharjah_coords) { [25.3573, 55.4038] }
    let(:abu_dhabi_coords) { [24.4667, 54.3667] }

    let!(:dubai)   { locations(:mall_location) }
    let!(:sharjah) { locations(:downtown_office) }
    let!(:abu_dhabi) { locations(:no_price_list) }

    context 'without radius' do
      it 'orders locations by distance ascending' do
        results = Location.nearby(latitude: dubai_coords[0], longitude: dubai_coords[1])

        expect(results.first).to eq(dubai)
        expect(results.second).to eq(sharjah)
        expect(results.last).to eq(abu_dhabi)
      end
    end

    context 'with radius' do
      it 'includes only locations within the given radius' do
        results = Location.nearby(latitude: dubai_coords[0], longitude: dubai_coords[1], radius_km: 30)

        expect(results).to include(dubai, sharjah)
        expect(results).not_to include(abu_dhabi)
      end
    end

    context 'edge case' do
      it 'returns empty if no locations have coordinates' do
        Location.update_all(coordinates: nil) # rubocop:disable Rails/SkipsModelValidations

        results = Location.nearby(latitude: dubai_coords[0], longitude: dubai_coords[1])
        expect(results).to be_empty
      end
    end
  end
end
