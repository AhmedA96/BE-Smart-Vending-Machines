# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LineItems::Create do
  describe '.call' do
    let(:order) { orders(:order_002) } # rubocop:disable Naming/VariableNumber
    let(:machine) { machines(:machine_001) } # rubocop:disable Naming/VariableNumber
    let(:variant) { variants(:coke_classic_12oz) }
    let(:item_hash) do
      {
        variant_id: variant.id,
        quantity: 2
      }
    end

    before do
      # Mock the Stock::Management service
      allow(Stock::Management).to receive(:call)

      # Mock variant price lookup
      allow(described_class).to receive(:variant_price).and_return(10.50)
    end

    context 'with valid parameters' do
      it 'creates a line item successfully' do
        expect { described_class.call(order, item_hash, machine) }.to change(order.line_items, :count).by(1)
      end

      it 'creates line item with correct attributes' do
        line_item = described_class.call(order, item_hash, machine)

        expect(line_item.variant_id).to eq(variant.id)
        expect(line_item.quantity).to eq(2)
        expect(line_item.price).to eq(10.50)
        expect(line_item.order).to eq(order)
      end

      it 'calls Stock::Management with correct parameters' do
        described_class.call(order, item_hash, machine)

        expect(Stock::Management).to have_received(:call).with(
          variant.id,
          2,
          machine.id
        )
      end

      it 'returns the created line item' do
        line_item = described_class.call(order, item_hash, machine)

        expect(line_item).to be_a(LineItem)
        expect(line_item).to be_persisted
      end

      it 'gets the variant price using the machine' do
        described_class.call(order, item_hash, machine)

        expect(described_class).to have_received(:variant_price).with(machine, variant)
      end
    end

    context 'when line item creation fails' do
      before do
        allow(order.line_items).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'raises an error and does not call Stock::Management' do
        expect { described_class.call(order, item_hash, machine) }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Stock::Management).not_to have_received(:call)
      end
    end

    context 'when Stock::Management fails' do
      before do
        allow(Stock::Management).to receive(:call).and_raise(StandardError, 'Stock management failed')
      end

      it 'raises an error but line item is still created' do
        expect { described_class.call(order, item_hash, machine) }.to raise_error('Stock management failed')
      end
    end

    context 'with different quantity values' do
      it 'handles string quantities' do
        item_hash_with_string = item_hash.merge(quantity: '5')
        line_item = described_class.call(order, item_hash_with_string, machine)

        expect(line_item.quantity).to eq(5)
      end

      it 'handles zero quantity' do
        item_hash_with_zero = item_hash.merge(quantity: 0)
        line_item = described_class.call(order, item_hash_with_zero, machine)

        expect(line_item.quantity).to eq(0)
      end
    end
  end

  describe '.variant_price' do
    let(:machine) { machines(:machine_001) } # rubocop:disable Naming/VariableNumber
    let(:variant) { variants(:coke_classic_12oz) }

    context 'when machine has a price list' do
      before do
        allow(described_class).to receive(:find_variant_price).and_return(15.75)
      end

      it 'returns the variant price from the price list' do
        price = described_class.variant_price(machine, variant)

        expect(price).to eq(15.75)
        expect(described_class).to have_received(:find_variant_price).with(variant, machine.price_list.id)
      end
    end

    context 'when machine is nil' do
      it 'returns 0' do
        price = described_class.variant_price(nil, variant)

        expect(price).to eq(0)
      end
    end

    context 'when machine has no price list' do
      let(:machine_without_price_list) { machines(:machine_no_price_list) }

      it 'returns 0' do
        price = described_class.variant_price(machine_without_price_list, variant)

        expect(price).to eq(0)
      end
    end

    context 'when price list exists but has no id' do
      let(:machine_with_nil_price_list) do
        machine = machines(:machine_001)
        allow(machine).to receive(:price_list).and_return(double('PriceList', id: nil))
        machine
      end

      it 'returns 0' do
        price = described_class.variant_price(machine_with_nil_price_list, variant)

        expect(price).to eq(0)
      end
    end
  end

  describe '.find_variant_price' do
    let(:variant) { variants(:coke_classic_12oz) }
    let(:price_list_id) { 1 }

    context 'when variant has price for the price list' do
      before do
        variant_with_price = double('VariantWithPrice', price: 25.50)
        allow(variant).to receive(:with_price_list).with(price_list_id).and_return(variant_with_price)
      end

      it 'returns the price as float' do
        price = described_class.find_variant_price(variant, price_list_id)

        expect(price).to eq(25.50)
        expect(variant).to have_received(:with_price_list).with(price_list_id)
      end
    end

    context 'when variant has no price for the price list' do
      before do
        allow(variant).to receive(:with_price_list).with(price_list_id).and_return(nil)
      end

      it 'returns 0.0' do
        price = described_class.find_variant_price(variant, price_list_id)

        expect(price).to eq(0.0)
      end
    end

    context 'when variant with_price_list returns object with nil price' do
      before do
        variant_with_nil_price = double('VariantWithPrice', price: nil)
        allow(variant).to receive(:with_price_list).with(price_list_id).and_return(variant_with_nil_price)
      end

      it 'returns 0.0' do
        price = described_class.find_variant_price(variant, price_list_id)

        expect(price).to eq(0.0)
      end
    end

    context 'when variant with_price_list returns object with string price' do
      before do
        variant_with_string_price = double('VariantWithPrice', price: '12.75')
        allow(variant).to receive(:with_price_list).with(price_list_id).and_return(variant_with_string_price)
      end

      it 'converts string price to float' do
        price = described_class.find_variant_price(variant, price_list_id)

        expect(price).to eq(12.75)
      end
    end

    context 'when variant with_price_list returns object with invalid price' do
      before do
        variant_with_invalid_price = double('VariantWithPrice', price: 'invalid')
        allow(variant).to receive(:with_price_list).with(price_list_id).and_return(variant_with_invalid_price)
      end

      it 'returns 0.0 for invalid price' do
        price = described_class.find_variant_price(variant, price_list_id)

        expect(price).to eq(0.0)
      end
    end
  end
end
