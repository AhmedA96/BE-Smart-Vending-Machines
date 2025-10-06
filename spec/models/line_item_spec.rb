# rubocop:disable Naming/VariableNumber
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LineItem, type: :model do
  describe 'associations' do
    it { should belong_to(:order) }
    it { should belong_to(:variant) }
  end

  describe 'validations' do
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).is_greater_than(0) }

    context 'variant availability for machine' do
      it 'is valid if the variant exists in machine_items' do
        order = orders(:order_001)
        variant = variants(:coke_classic_12oz)
        line_item = LineItem.new(order:, variant:, quantity: 1)

        expect(line_item).to be_valid
      end

      it 'is invalid if the variant does not belong to the machine' do
        order = orders(:order_001)
        variant = variants(:sprite_12oz)
        line_item = LineItem.new(order:, variant:, quantity: 1)

        expect(line_item).not_to be_valid
        expect(line_item.errors[:base]).to include(
          I18n.t('errors.orders.variant_not_available_for_machine')
        )
      end
    end

    context 'within machine item limit' do
      it 'is valid when within limit' do
        order = orders(:order_004)
        variant = variants(:coke_classic_12oz)

        line_item = LineItem.new(order:, variant:, quantity: 1)
        expect(line_item).to be_valid
      end

      it 'is invalid when exceeding max_items_per_order' do
        order = Order.create!(number: 'ORD-TEST-LIMIT',
                              machine: machines(:limited_machine),
                              status: 'cart',
                              total: 0, items_total: 0)
        variant = variants(:coke_classic_12oz)

        line_item = LineItem.new(order:, variant:, quantity: 4)

        expect(line_item).not_to be_valid
        expect(line_item.errors[:base]).to include(
          I18n.t('errors.orders.exceeds_machine_max_items_limit', count: order.machine.max_items_per_order)
        )
      end
    end

    context 'sufficient stock' do
      it 'is valid if stock is enough' do
        order = orders(:order_001)
        variant = variants(:coke_classic_12oz)
        line_item = LineItem.new(order:, variant:, quantity: 1)

        allow(variant).to receive(:machine_available_stock).with(order.machine).and_return(5)

        expect(line_item).to be_valid
      end

      it 'is invalid if stock is insufficient' do
        order = orders(:order_001)
        variant = variants(:kit_kat_42g)
        line_item = LineItem.new(order:, variant:, quantity: 5)

        allow(Variant).to receive(:find).with(variant.id).and_return(variant)
        allow(variant).to receive(:machine_available_stock).with(order.machine).and_return(2)

        expect(line_item).not_to be_valid
        expect(line_item.errors[:base]).to include(
          I18n.t('errors.orders.required_quantity_is_not_available_in_the_machine', product_name: variant.name)
        )
      end
    end
  end

  describe '#available_quantity' do
    it 'calls variant.machine_available_stock with order.machine' do
      order = orders(:order_001)
      variant = variants(:coke_classic_12oz)
      line_item = LineItem.new(order:, variant:, quantity: 1)

      expect(Variant).to receive(:find).with(variant.id).and_return(variant)
      expect(variant).to receive(:machine_available_stock).with(order.machine)

      line_item.send(:available_quantity)
    end
  end
end

# rubocop:enable Naming/VariableNumber
