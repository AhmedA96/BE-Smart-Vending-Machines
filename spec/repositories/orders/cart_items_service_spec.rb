# rubocop:disable Naming/VariableNumber
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Orders::CartItemsService, type: :service do
  fixtures :machines, :price_lists, :variants, :orders, :price_list_items, :line_items

  let(:machine) { machines(:machine_001) }
  let(:price_list) { price_lists(:standard_pricing) }
  let(:variant1) { variants(:coke_classic_12oz) }
  let(:variant2) { variants(:pepsi_cola_12oz) }
  let(:variant3) { variants(:kit_kat_42g) }
  let(:order) { orders(:order_001) }

  subject(:service) { described_class.new(order, cart_items) }

  before do
    # Mock Stock::Management to avoid actual stock operations
    allow(Stock::Management).to receive(:call).and_return(true)
    allow(LineItems::Create).to receive(:call).and_return(true)
  end

  describe '#call' do
    context 'with valid cart items' do
      let(:cart_items) do
        [
          { variant_id: variant1.id, quantity: 2 },
          { variant_id: variant2.id, quantity: 1 }
        ]
      end

      it 'processes cart items successfully' do
        expect { service.call }.not_to raise_error
      end

      it 'validates cart items' do
        expect(service).to receive(:validate_cart_items!)
        service.call
      end

      it 'processes cart items' do
        expect(service).to receive(:process_cart_items)
        service.call
      end

      it 'validates item limit' do
        expect(service).to receive(:validate_item_limit!)
        service.call
      end
    end

    context 'when machine is not active' do
      let(:cart_items) { [{ variant_id: variant1.id, quantity: 1 }] }

      before { machine.update!(status: 'Inactive') }

      it 'raises an error' do
        expect { service.call }.to raise_error('Machine not available')
      end
    end

    context 'when cart items are empty' do
      let(:cart_items) { [] }

      it 'raises an error' do
        expect { service.call }.to raise_error('Cart items cannot be empty')
      end
    end

    context 'when cart items are blank' do
      let(:cart_items) { nil }

      it 'raises an error' do
        expect { service.call }.to raise_error('Cart items cannot be empty')
      end
    end
  end

  describe '#validate_cart_item!' do
    context 'with invalid variant ID' do
      let(:cart_items) { [{ variant_id: '', quantity: 1 }] }

      it 'raises an error for blank variant ID' do
        expect { service.call }.to raise_error('Invalid variant ID')
      end
    end

    context 'with non-existent variant ID' do
      let(:cart_items) { [{ variant_id: 99_999, quantity: 1 }] }

      it 'raises an error for non-existent variant' do
        expect { service.call }.to raise_error('Invalid variant ID')
      end
    end

    context 'with negative quantity' do
      let(:cart_items) { [{ variant_id: variant1.id, quantity: -1 }] }

      it 'raises an error for negative quantity' do
        expect { service.call }.to raise_error('Invalid quantity')
      end
    end

    context 'with zero quantity' do
      let(:cart_items) { [{ variant_id: variant1.id, quantity: 0 }] }

      it 'allows zero quantity for removal' do
        expect { service.call }.not_to raise_error
      end
    end

    context 'with variant not in machine price list' do
      # Create a variant that's not in the price list
      let(:variant_not_in_list) { create(:variant, name: 'Unavailable Product') }
      let(:cart_items) { [{ variant_id: variant_not_in_list.id, quantity: 1 }] }

      it 'raises an error' do
        expect { service.call }.to raise_error("Variant #{variant_not_in_list.name} not available for this machine")
      end
    end

    context 'when stock validation fails' do
      let(:cart_items) { [{ variant_id: variant1.id, quantity: 1 }] }

      before do
        allow(Stock::Management).to receive(:call).and_raise(StandardError.new('Insufficient stock'))
      end

      it 'raises a stock validation error' do
        expect { service.call }.to raise_error("Stock validation failed for #{variant1.name}: Insufficient stock")
      end
    end
  end

  describe '#process_cart_items' do
    context 'creating new line items' do
      let(:cart_items) { [{ variant_id: variant1.id, quantity: 2 }] }

      before do
        # Ensure no existing line item for this variant
        order.line_items.where(variant_id: variant1.id).destroy_all
      end

      it 'calls LineItems::Create for new items' do
        expect(LineItems::Create).to receive(:call).with(order, { variant_id: variant1.id, quantity: 2 }, machine)
        service.call
      end
    end

    context 'updating existing line items' do
      let(:existing_line_item) { line_items(:order_001_coke) }
      let(:cart_items) { [{ variant_id: existing_line_item.variant_id, quantity: 3 }] }

      it 'updates existing line item quantity' do
        expect { service.call }.to change { existing_line_item.reload.quantity }.from(existing_line_item.quantity).to(3)
      end

      it 'calls stock management for the quantity difference' do
        original_quantity = existing_line_item.quantity
        quantity_diff = 3 - original_quantity
        expect(Stock::Management).to receive(:call).with(existing_line_item.variant_id, quantity_diff, machine.id)
        service.call
      end
    end

    context 'removing existing line items with zero quantity' do
      let(:existing_line_item) { line_items(:order_001_coke) }
      let(:cart_items) { [{ variant_id: existing_line_item.variant_id, quantity: 0 }] }

      it 'removes the line item' do
        expect { service.call }.to change { order.line_items.count }.by(-1)
      end

      it 'releases stock back' do
        expect(Stock::Management).to receive(:call).with(existing_line_item.variant_id, -existing_line_item.quantity,
                                                         machine.id)
        service.call
      end
    end

    context 'when updating with same quantity' do
      let(:existing_line_item) { line_items(:order_001_coke) }
      let(:cart_items) { [{ variant_id: existing_line_item.variant_id, quantity: existing_line_item.quantity }] }

      before do
        # Reset the mock to avoid interference from validation calls
        allow(Stock::Management).to receive(:call).and_return(true)
      end

      it 'does not update the line item' do
        expect { service.call }.not_to(change { existing_line_item.reload.quantity })
      end

      it 'does not call stock management for processing' do
        # Allow validation calls but expect no processing calls
        expect(Stock::Management).to receive(:call).at_most(1).times # for validation only
        service.call
      end
    end
  end

  describe '#remove_unlisted_items' do
    let(:line_item1) { line_items(:order_001_coke) }
    let(:line_item2) { line_items(:order_001_kit_kat) }
    let(:line_item3) { line_items(:order_002_coke) }

    context 'when should_remove_unlisted_items? returns true' do
      let(:cart_items) { [{ variant_id: line_item1.variant_id, quantity: 1 }] }

      before do
        allow(service).to receive(:should_remove_unlisted_items?).and_return(true)
      end

      it 'removes unlisted items' do
        initial_count = order.line_items.count
        service.call
        expect(order.line_items.count).to be < initial_count
      end

      it 'releases stock for removed items' do
        unlisted_items = order.line_items.where.not(variant_id: line_item1.variant_id)

        unlisted_items.each do |item|
          expect(Stock::Management).to receive(:call).with(item.variant_id, -item.quantity, machine.id)
        end

        service.call
      end
    end

    context 'when should_remove_unlisted_items? returns false' do
      let(:cart_items) { [{ variant_id: line_item1.variant_id, quantity: 1 }] }

      it 'does not remove unlisted items' do
        expect { service.call }.not_to(change { order.line_items.count })
      end
    end
  end

  describe '#validate_item_limit!' do
    context 'when total items are within limit' do
      let(:cart_items) do
        [
          { variant_id: variant1.id, quantity: 5 },
          { variant_id: variant2.id, quantity: 3 }
        ]
      end

      it 'does not raise an error' do
        expect { service.call }.not_to raise_error
      end
    end

    context 'when machine has no item limit' do
      let(:cart_items) do
        [
          { variant_id: variant1.id, quantity: 50 },
          { variant_id: variant2.id, quantity: 30 }
        ]
      end

      before { machine.update!(max_items_per_order: nil) }

      it 'does not raise an error' do
        expect { service.call }.not_to raise_error
      end
    end

    context 'when total items equal the limit' do
      let(:cart_items) do
        [
          { variant_id: variant1.id, quantity: 6 },
          { variant_id: variant2.id, quantity: 4 }
        ]
      end

      it 'does not raise an error' do
        expect { service.call }.not_to raise_error
      end
    end
  end

  describe 'error handling' do
    context 'when stock validation fails during update' do
      let(:existing_line_item) { line_items(:order_001_coke) }
      let(:cart_items) { [{ variant_id: existing_line_item.variant_id, quantity: 5 }] }

      before do
        allow(Stock::Management).to receive(:call).and_raise(StandardError.new('Not enough stock'))
      end

      it 'raises a stock validation error' do
        variant = existing_line_item.variant
        expect { service.call }.to raise_error("Stock validation failed for #{variant.name}: Not enough stock")
      end
    end
  end

  describe 'integration scenarios' do
    context 'mixed operations: create, update, and remove' do
      let(:existing_line_item) { line_items(:order_001_coke) }
      let(:cart_items) do
        [
          { variant_id: existing_line_item.variant_id, quantity: 3 }, # Update existing
          { variant_id: variant2.id, quantity: 1 },                   # Create new
          { variant_id: variant3.id, quantity: 0 }                    # Remove (if exists)
        ]
      end

      before do
        # Ensure variant2 doesn't have an existing line item
        order.line_items.where(variant_id: variant2.id).destroy_all
      end

      it 'handles all operations correctly' do
        expect(LineItems::Create).to receive(:call).with(order, { variant_id: variant2.id, quantity: 1 }, machine)

        original_quantity = existing_line_item.quantity
        quantity_diff = 3 - original_quantity
        expect(Stock::Management).to receive(:call).with(existing_line_item.variant_id, quantity_diff, machine.id)

        expect { service.call }.to change { existing_line_item.reload.quantity }.from(original_quantity).to(3)
      end
    end
  end
end

# rubocop:enable Naming/VariableNumber
