# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PriceList, type: :model do
  describe 'associations' do
    it { should have_many(:price_list_items) }

    let(:price_list) { create(:price_list) }
    let(:product) { create(:product) }
    let(:variant) { create(:variant, product: product) }

    it 'can have many products through price_list_items' do
      create(:price_list_item, price_list: price_list, product: product)

      expect(price_list.products).to include(product)
    end

    it 'can have multiple products' do
      products = create_list(:product, 3)
      products.each do |product|
        variant = create(:variant, product: product)
        create(:price_list_item, price_list: price_list, product: product, variant: variant)
      end

      expect(price_list.products.count).to eq(3)
      expect(price_list.products).to match_array(products)
    end
  end
end
