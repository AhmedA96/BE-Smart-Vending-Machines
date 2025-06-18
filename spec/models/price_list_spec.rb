# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PriceList, type: :model do
  fixtures :price_lists, :variants, :price_list_items, :locations

  describe 'associations' do
    it { should have_many(:price_list_items) }
    it { should have_many(:variants).through(:price_list_items) }
    it { should have_many(:locations) }

    let(:price_list) { price_lists(:standard_pricing) }
    let(:variant) { variants(:pepsi_cola_12oz) }

    it 'can have many variants through price_list_items' do
      # This relationship should already exist in fixtures
      expect(price_list.variants).to include(variant)
    end

    it 'can have multiple variants' do
      # Load variants from fixtures
      variant1 = variants(:pepsi_cola_12oz)
      variant2 = variants(:kit_kat_42g)
      variant3 = variants(:coke_classic_12oz)

      # These price list items should already exist in fixtures
      price_list_items(:pepsi_standard_price)
      price_list_items(:kit_kat_standard_price)
      price_list_items(:coke_standard_price)

      expect(price_list.variants).to include(variant1, variant2, variant3)
      expect(price_list.price_list_items.count).to eq(3)
    end
  end
end
