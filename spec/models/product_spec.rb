# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product, type: :model do
  fixtures :products, :brands, :categories, :variants, :product_categories,
           :machines, :machine_items, :price_lists, :price_list_items

  describe 'associations' do
    it { should have_many_attached(:images) }
    it { should have_many(:product_categories).dependent(:destroy) }
    it { should have_many(:categories).through(:product_categories) }
    it { should have_many(:variants).dependent(:destroy) }
    it { should have_many(:product_translations).dependent(:destroy) }

    it { should belong_to(:brand).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[Active Inactive]) }
    it { should validate_numericality_of(:max_orderable_quantity).is_greater_than(0).allow_nil }
    it { should validate_presence_of(:position) }
    it { should validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(1) }
  end

  describe 'scopes' do
    describe '.filtered_by_machine' do
      it 'returns products filtered by machine' do
        machine = machines(:machine_001) # rubocop:disable Naming/VariableNumber
        product = products(:coke_classic)
        expect(Product.filtered_by_machine(machine.id)).to include(product)
      end
    end

    describe '.order_by_position' do
      it 'orders products by position' do
        expect(Product.order_by_position.map(&:id)).to eq(Product.order(:position).ids)
      end
    end

    describe '.by_category' do
      it 'returns products by category' do
        category = categories(:beverages)
        product = products(:coke_classic)
        expect(Product.by_category(category.id)).to include(product)
      end
    end

    describe '.by_price_range_for_price_list' do
      it 'returns products within price range for price list' do
        price_list = price_lists(:standard_pricing)
        product = products(:coke_classic)
        expect(Product.by_price_range_for_price_list(price_list.id, 5, 15)).to include(product)
      end
    end

    describe '.sort_by_price' do
      it 'sorts products by price ascending' do
        sorted = Product.sort_by_price(:asc)

        expect(sorted.first).to eq(products(:pepsi_cola))
        expect(sorted.second).to eq(products(:coke_classic))
      end
    end

    describe '.with_stock_availability' do
      it 'returns products with stock availability' do
        machine = machines(:machine_001) # rubocop:disable Naming/VariableNumber
        product = products(:coke_classic)
        expect(Product.with_stock_availability(machine, 1)).to include(product)
      end
    end

    describe '.alternatives' do
      it 'returns alternative products in the same category' do
        category = categories(:beverages)
        product = products(:coke_classic)
        alt_product = products(:pepsi_cola)
        expect(Product.alternatives(category.id, product.id)).to include(alt_product)
        expect(Product.alternatives(category.id, product.id)).not_to include(product)
      end
    end

    describe '.with_price_list' do
      it 'returns products with a given price list' do
        price_list = price_lists(:standard_pricing)
        product = products(:coke_classic)
        expect(Product.with_price_list(price_list.id)).to include(product)
      end
    end

    describe '.active' do
      it 'returns only active products' do
        active = products(:coke_classic)
        inactive = products(:pepsi_cola) # assuming soda is inactive
        expect(Product.active).to include(active)
        expect(Product.active).not_to include(inactive)
      end
    end

    describe '#master' do
      it 'returns the master variant' do
        product = products(:coke_classic)
        expect(product.master).to eq(variants(:coke_classic_12oz))
      end
    end
  end
end
