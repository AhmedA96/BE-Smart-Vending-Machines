# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PriceList, type: :model do
  describe 'associations' do
    it { should have_many(:price_list_items) }
    it { should have_many(:variants).through(:price_list_items) }
    it { should have_many(:locations) }

    let(:price_list) { create(:price_list) }
    let(:variant) { create(:variant) }

    it 'can have many variants through price_list_items' do
      create(:price_list_item, price_list: price_list, variant: variant)

      expect(price_list.variants).to include(variant)
    end

    it 'can have multiple variants' do
      variants = create_list(:variant, 3)
      variants.each do |variant|
        create(:price_list_item, price_list: price_list, variant: variant)
      end

      expect(price_list.variants.count).to eq(3)
      expect(price_list.variants).to match_array(variants)
    end
  end
end
