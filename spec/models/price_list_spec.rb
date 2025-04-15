# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PriceList, type: :model do
  describe 'associations' do
    let(:price_list) { create(:price_list) }
    let(:product) { create(:product) }

    xit 'can have many products through price_list_items' do
      create(:price_list_item, price_list: price_list, product: product)

      expect(price_list.products).to include(product)
    end

    xit 'can have multiple products' do
      products = create_list(:product, 3)
      products.each do |product|
        create(:price_list_item, price_list: price_list, product: product)
      end

      expect(price_list.products.count).to eq(3)
      expect(price_list.products).to match_array(products)
    end
  end
end
