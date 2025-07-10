# rubocop:disable Naming/VariableNumber
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Machines::Filter, type: :service do
  describe '.call' do
    it 'filters by location_id' do
      result = described_class.call(location_id: locations(:downtown_office).id)
      expect(result).to contain_exactly(machines(:machine_001)) # rubocop:disable Naming/VariableNumber
    end

    it 'filters by category_id' do
      result = described_class.call(category_id: machine_categories(:snack_machines).id)
      expect(result).to contain_exactly(machines(:machine_001), machines(:machine_no_price_list)) # rubocop:disable Naming/VariableNumber
    end

    it 'filters by brand_id' do
      result = described_class.call(brand_id: brands(:coca_cola).id)
      expect(result).to contain_exactly(machines(:machine_001))
    end

    it 'filters by location and brand' do
      result = described_class.call(
        brand_id: brands(:coca_cola).id,
        location_id: locations(:downtown_office).id
      )
      expect(result).to contain_exactly(machines(:machine_001))
    end

    it 'returns nothing if brand and location do not match' do
      result = described_class.call(
        brand_id: brands(:coca_cola).id,
        location_id: locations(:mall_location).id
      )
      expect(result).to be_empty
    end

    it 'does not return inactive machines' do
      result = described_class.call(location_id: locations(:downtown_office).id)
      expect(result).not_to include(machines(:machine_inactive))
    end

    it 'returns all active machines if no filters given' do
      result = described_class.call({})
      expect(result).to contain_exactly(machines(:machine_001), machines(:limited_machine),
                                        machines(:machine_no_price_list))
    end
  end
end

# rubocop:enable Naming/VariableNumber
