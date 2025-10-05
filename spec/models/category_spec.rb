# rubocop:disable Naming/VariableNumber
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:presentation) }
  end

  describe 'associations' do
    it { should have_many(:product_categories).dependent(:destroy) }
    it { should have_many(:products).through(:product_categories) }
    it { should have_many(:category_translations).dependent(:destroy) }
  end

  describe 'default values' do
    let(:category) { categories(:beverages) }

    it 'sets active to true by default' do
      expect(category.active).to be true
    end

    it 'sets position to 0 by default' do
      expect(category.position).to eq(0)
    end
  end

  describe '.with_brands' do
    it 'returns categories with their associated brands' do
      category = categories(:beverages)
      brand = brands(:coca_cola)

      expect(category.brands).to include(brand)

      result = Category.with_brands
      category_hash = result.find { |h| h[:id] == category.id }

      expect(category_hash).to include(
        id: category.id,
        name: category.name,
        brands: include(id: brand.id, name: brand.name)
      )
    end
  end

  describe '.for_machine' do
    it 'returns categories available for the given machine' do
      machine = machines(:machine_001)
      category = categories(:beverages)

      result = Category.for_machine(machine)

      expect(result).to include(category)
    end

    it 'does not return categories without products for the machine' do
      machine = machines(:machine_002)
      unrelated_category = categories(:snacks)

      result = Category.for_machine(machine)

      expect(result).not_to include(unrelated_category)
    end
  end
end

# rubocop:enable Naming/VariableNumber
