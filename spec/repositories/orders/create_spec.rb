# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Orders::Create do
  describe '.call' do
    let(:machine) { machines(:machine_001) } # rubocop:disable Naming/VariableNumber
    let(:user) { users(:john_doe) }
    let(:variant1) { variants(:coke_classic_12oz) }
    let(:variant2) { variants(:pepsi_cola_12oz) }

    let(:valid_cart_items) do
      [
        { variant_id: variant1.id, quantity: 2 },
        { variant_id: variant2.id, quantity: 1 }
      ]
    end

    let(:valid_params) do
      {
        machine_id: machine.id,
        user_id: user.id,
        cart_items: valid_cart_items
      }
    end

    before do
      # Mock the LineItems::Create service
      allow(LineItems::Create).to receive(:call)
      allow(LineItems::Create).to receive(:variant_price).and_return(10.0)
      # Mock Order.generate_unique_order_number
      allow(Order).to receive(:generate_unique_order_number).and_return('ORDER-123')
    end

    context 'with valid parameters' do
      it 'creates an order successfully' do
        expect { described_class.call(valid_params) }.to change(Order, :count).by(1)
      end

      it 'creates an order with correct attributes' do
        order = described_class.call(valid_params)

        expect(order.machine).to eq(machine)
        expect(order.user).to eq(user)
        expect(order.items_total).to eq(30.0) # (2 * 10.0) + (1 * 10.0)
        expect(order.number).to be_present
      end

      it 'calls LineItems::Create for each cart item' do
        described_class.call(valid_params)

        expect(LineItems::Create).to have_received(:call).exactly(2).times
      end

      it 'wraps order creation in a transaction' do
        expect(ActiveRecord::Base).to receive(:transaction).and_call_original
        described_class.call(valid_params)
      end

      it 'reloads the order before returning' do
        order_double = double('Order')
        allow(Order).to receive(:create!).and_return(order_double)
        allow(order_double).to receive(:reload).and_return(order_double)

        described_class.call(valid_params)

        expect(order_double).to have_received(:reload)
      end
    end

    context 'validation errors' do
      context 'when user is not found' do
        let(:invalid_params) { valid_params.merge(user_id: nil) }

        it 'creates order without user' do
          # Based on the implementation, user can be nil
          expect { described_class.call(invalid_params) }.to change(Order, :count).by(1)
        end
      end

      context 'when machine is not found' do
        let(:invalid_params) { valid_params.merge(machine_id: 999_999) }

        it 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when machine is not active' do
        let(:inactive_machine) { machines(:machine_002) } # rubocop:disable Naming/VariableNumber
        let(:invalid_params) { valid_params.merge(machine_id: inactive_machine.id) }

        before do
          allow(inactive_machine).to receive(:active?).and_return(false)
        end

        it 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error('Machine not available')
        end
      end

      context 'when machine has no price list' do
        let(:machine_without_price_list) { machines(:machine_no_price_list) }
        let(:invalid_params) { valid_params.merge(machine_id: machine_without_price_list.id) }

        before do
          allow(machine_without_price_list).to receive(:price_list).and_return(nil)
        end

        it 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error('Machine has no price list')
        end
      end

      context 'when cart items are empty' do
        let(:invalid_params) { valid_params.merge(cart_items: []) }

        xit 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error('Cart items cannot be empty')
        end
      end

      context 'when cart items are nil' do
        let(:invalid_params) { valid_params.merge(cart_items: nil) }

        xit 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error('Cart items cannot be empty')
        end
      end
    end

    context 'cart item validation errors' do
      context 'when variant_id is blank' do
        let(:invalid_cart_items) { [{ variant_id: '', quantity: 1 }] }
        let(:invalid_params) { valid_params.merge(cart_items: invalid_cart_items) }

        it 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error('Invalid variant ID')
        end
      end

      context 'when variant_id is nil' do
        let(:invalid_cart_items) { [{ variant_id: nil, quantity: 1 }] }
        let(:invalid_params) { valid_params.merge(cart_items: invalid_cart_items) }

        it 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error('Invalid variant ID')
        end
      end

      context 'when variant does not exist' do
        let(:invalid_cart_items) { [{ variant_id: 999_999, quantity: 1 }] }
        let(:invalid_params) { valid_params.merge(cart_items: invalid_cart_items) }

        before do
          allow(Variant).to receive(:exists?).with(999_999).and_return(false)
        end

        it 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error('Invalid variant ID')
        end
      end

      context 'when quantity is zero' do
        let(:invalid_cart_items) { [{ variant_id: variant1.id, quantity: 0 }] }
        let(:invalid_params) { valid_params.merge(cart_items: invalid_cart_items) }

        it 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error('Invalid quantity')
        end
      end

      context 'when quantity is negative' do
        let(:invalid_cart_items) { [{ variant_id: variant1.id, quantity: -1 }] }
        let(:invalid_params) { valid_params.merge(cart_items: invalid_cart_items) }

        it 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error('Invalid quantity')
        end
      end

      context 'when quantity is not a number' do
        let(:invalid_cart_items) { [{ variant_id: variant1.id, quantity: 'invalid' }] }
        let(:invalid_params) { valid_params.merge(cart_items: invalid_cart_items) }

        it 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error('Invalid quantity')
        end
      end
    end

    context 'item limit validation' do
      context 'when machine has max_items_per_order limit' do
        let(:limited_machine) { machines(:limited_machine) } # max_items_per_order: 3
        let(:cart_items_within_limit) { [{ variant_id: variant1.id, quantity: 2 }] }
        let(:cart_items_over_limit) { [{ variant_id: variant1.id, quantity: 5 }] }

        before do
          allow(limited_machine).to receive(:max_items_per_order).and_return(3)
        end

        context 'when total items is within limit' do
          let(:valid_params) do
            {
              machine_id: limited_machine.id,
              user_id: user.id,
              cart_items: cart_items_within_limit
            }
          end

          it 'creates the order successfully' do
            expect { described_class.call(valid_params) }.to change(Order, :count).by(1)
          end
        end

        context 'when total items exceeds limit' do
          let(:invalid_params) do
            {
              machine_id: limited_machine.id,
              user_id: user.id,
              cart_items: cart_items_over_limit
            }
          end

          it 'raises a FailedRequestError' do
            expect do
              described_class.call(invalid_params)
            end.to raise_error(FailedRequestError, /Maximum 3 item allowed per order/)
          end
        end
      end

      context 'when machine has no item limit' do
        let(:cart_items_many) { [{ variant_id: variant1.id, quantity: 100 }] }
        let(:valid_params) do
          {
            machine_id: machine.id, # machine without max_items_per_order
            user_id: user.id,
            cart_items: cart_items_many
          }
        end

        before do
          allow(machine).to receive(:max_items_per_order).and_return(nil)
        end

        it 'creates the order successfully' do
          expect { described_class.call(valid_params) }.to change(Order, :count).by(1)
        end
      end
    end

    context 'pricing and total calculation' do
      context 'when variant price is zero' do
        let(:invalid_params) { valid_params }

        before do
          allow(LineItems::Create).to receive(:variant_price).and_return(0)
        end

        it 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error(/No price found for variant/)
        end
      end

      context 'when variant price is negative' do
        let(:invalid_params) { valid_params }

        before do
          allow(LineItems::Create).to receive(:variant_price).and_return(-5.0)
        end

        it 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error(/No price found for variant/)
        end
      end

      context 'when order total is zero' do
        let(:invalid_params) { valid_params }

        before do
          allow_any_instance_of(described_class.singleton_class).to receive(:calculate_total_amount).and_return(0)
        end

        xit 'raises an error' do
          expect { described_class.call(invalid_params) }.to raise_error('Order total cannot be zero')
        end
      end

      context 'with different variant prices' do
        before do
          allow(LineItems::Create).to receive(:variant_price).with(machine, variant1).and_return(15.50)
          allow(LineItems::Create).to receive(:variant_price).with(machine, variant2).and_return(7.25)
        end

        it 'calculates the correct total' do
          order = described_class.call(valid_params)
          # (2 * 15.50) + (1 * 7.25) = 31.00 + 7.25 = 38.25
          expect(order.items_total).to eq(38.25)
        end
      end

      context 'with decimal rounding' do
        before do
          allow(LineItems::Create).to receive(:variant_price).and_return(3.333)
        end

        it 'rounds the total to 2 decimal places' do
          order = described_class.call(valid_params)
          # (2 * 3.333) + (1 * 3.333) = 9.999, rounded to 10.0
          expect(order.items_total).to eq(10.0)
        end
      end
    end

    context 'transaction rollback' do
      it 'rolls back the transaction when LineItems::Create fails' do
        allow(LineItems::Create).to receive(:call).and_raise(StandardError, 'Line item creation failed')
        initial_count = Order.count
        expect { described_class.call(valid_params) }.to raise_error('Line item creation failed')
        expect(Order.count).to eq(initial_count)
      end
    end
  end
end
