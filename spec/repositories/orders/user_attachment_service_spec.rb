# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Orders::UserAttachmentService do
  let(:user) { users(:john_doe) }
  let(:machine) { machines(:machine_001) } # rubocop:disable Naming/VariableNumber
  let(:guest_order) { orders(:guest_cart_order) }

  before do
    guest_order.update!(machine: machine, user: nil, status: 'cart')
    # Add a line item to the guest cart
    guest_order.line_items.create!(
      variant: variants(:pepsi_cola_12oz),
      quantity: 2
    )

    # Ensure price list item exists
    price_lists(:premium_pricing).price_list_items.create!(
      variant: variants(:pepsi_cola_12oz),
      price: 1000
    )
  end

  context 'when user has no existing cart for the machine' do
    it 'assigns the guest order to the user' do
      service = described_class.new(guest_order, user.id)
      result = service.call

      expect(result.user_id).to eq(user.id)
      expect(Order.exists?(id: guest_order.id)).to be true
    end
  end

  context 'when user already has a cart for the same machine' do
    let!(:existing_user_cart) do
      Order.create!(
        user: user,
        machine: machine,
        status: 'cart',
        number: 'ORD-2024-005'
      )
    end

    it 'merges items into user cart and destroys the guest cart' do
      # Add an existing line item with same variant
      existing_user_cart.line_items.create!(
        variant: variants(:pepsi_cola_12oz),
        quantity: 1
      )

      service = described_class.new(guest_order, user.id)
      result = service.call

      expect(result.id).to eq(existing_user_cart.id)
      expect(result.line_items.find_by(variant: variants(:pepsi_cola_12oz)).quantity).to eq(3)
      expect(Order.exists?(id: guest_order.id)).to be false
    end
  end
end
