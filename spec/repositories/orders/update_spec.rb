# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Orders::Update do
  fixtures :users, :orders, :machines, :variants, :price_lists, :price_list_items, :line_items

  let(:user) { users(:john_doe) }
  let(:machine) { machines(:machine_001) } # rubocop:disable Naming/VariableNumber
  let(:variant) { variants(:coke_classic_12oz) }

  describe '.call' do
    context 'when updating cart items of a guest cart' do
      let(:guest_cart) { orders(:guest_cart_order) }

      before do
        guest_cart.update!(machine: machine, user: nil, status: 'cart')

        # Ensure variant is valid in price list
        price_lists(:standard_pricing).price_list_items.find_or_create_by!(
          variant: variant
        ) do |pli|
          pli.price = 1000
        end
      end

      it 'adds items to the cart and recalculates totals' do
        params = {
          cart_items: [{ variant_id: variant.id, quantity: 2 }]
        }

        updated_order = described_class.call(guest_cart.id, params)

        expect(updated_order.line_items.count).to eq(1)
        expect(updated_order.line_items.first.variant_id).to eq(variant.id)
        expect(updated_order.line_items.first.quantity).to eq(2)
      end
    end

    context 'when assigning guest cart to a user' do
      let(:guest_cart) { orders(:guest_cart_order) }

      before do
        guest_cart.update!(machine: machine, user: nil, status: 'cart')
      end

      it 'attaches user to the order using UserAttachmentService' do
        expect(Orders::UserAttachmentService).to receive(:new)
          .with(guest_cart, user.id)
          .and_call_original

        described_class.call(guest_cart.id, { user_id: user.id })

        expect(guest_cart.reload.user_id).to eq(user.id)
      end
    end

    context 'when updating attributes like payment_method' do
      let(:user_cart) { orders(:order_002) } # rubocop:disable Naming/VariableNumber

      before do
        user_cart.update!(user: user, machine: machine, status: 'cart', payment_method: nil)
      end

      it 'updates the order attributes' do
        updated_order = described_class.call(user_cart.id, {
                                               user_id: user.id,
                                               payment_method: 'wallet'
                                             })

        expect(updated_order.payment_method).to eq('wallet')
      end
    end

    context 'when the order is not in cart status' do
      let(:paid_order) { orders(:order_001) } # rubocop:disable Naming/VariableNumber

      before do
        paid_order.update!(status: 'paid')
      end

      it 'raises an error' do
        expect do
          described_class.call(paid_order.id, { payment_method: 'wallet' })
        end.to raise_error('Cannot update order that is not in cart status')
      end
    end
  end
end
