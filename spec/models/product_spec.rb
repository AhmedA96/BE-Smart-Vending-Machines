# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product, type: :model do
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
    let(:brand) { create(:brand) }
    let(:category) { create(:category) }
    let(:product) { create(:product, brand: brand, status: 'Active', position: 2) }
    let(:variant) { create(:variant, product: product, is_master: true) }

    describe '.filtered_by_machine' do
      it 'returns products filtered by machine' do
        machine = create(:machine)
        variant = create(:variant, product: product)
        create(:machine_item, machine: machine, variant: variant)
        expect(Product.filtered_by_machine(machine.id)).to include(product)
      end
    end

    describe '.order_by_position' do
      it 'orders products by position' do
        product1 = create(:product, position: 1)
        product2 = create(:product, position: 2)
        expect(Product.order_by_position).to eq([product1, product2])
      end
    end

    describe '.by_category' do
      it 'returns products by category' do
        product.product_categories.create!(category: category)
        expect(Product.by_category(category.id)).to include(product)
      end
    end

    describe '.by_price_range_for_price_list' do
      it 'returns products within price range for price list' do
        price_list = create(:price_list)
        variant = create(:variant, product: product)
        create(:price_list_item, price_list: price_list, variant: variant, price: 10)
        expect(Product.by_price_range_for_price_list(price_list.id, 5, 15)).to include(product)
      end
    end

    describe '.sort_by_price' do
      it 'sorts products by price' do
        price_list = create(:price_list)
        variant1 = create(:variant, product: product)
        variant2 = create(:variant, product: create(:product))
        create(:price_list_item, price_list: price_list, variant: variant1, price: 10)
        create(:price_list_item, price_list: price_list, variant: variant2, price: 5)
        sorted = Product.sort_by_price(:asc)
        expect(sorted.first).to eq(variant2.product)
      end
    end

    describe '.with_stock_availability' do
      it 'returns products with stock availability' do
        machine = create(:machine)
        variant = create(:variant, product: product)
        create(:machine_item, machine: machine, variant: variant, stock: 5)
        expect(Product.with_stock_availability(machine, 1)).to include(product)
      end
    end

    describe '.alternatives' do
      it 'returns alternative products in the same category' do
        product.product_categories.create!(category: category)
        create(:variant, product: product)

        other_product = create(:product)
        create(:variant, product: other_product)
        other_product.product_categories.create!(category: category)

        expect(Product.alternatives(category.id, product.id)).to include(other_product)
        expect(Product.alternatives(category.id, product.id)).not_to include(product)
      end
    end

    describe '.with_price_list' do
      it 'returns products with a given price list' do
        price_list = create(:price_list)
        variant = create(:variant, product: product)
        create(:price_list_item, price_list: price_list, variant: variant)
        expect(Product.with_price_list(price_list.id)).to include(product)
      end
    end

    describe '.active' do
      it 'returns only active products' do
        inactive_product = create(:product, status: 'Inactive')
        expect(Product.active).to include(product)
        expect(Product.active).not_to include(inactive_product)
      end
    end

    describe '#master' do
      it 'returns the master variant' do
        master_variant = create(:variant, product: product, is_master: true)
        expect(product.master).to eq(master_variant)
      end
    end
  end
end
