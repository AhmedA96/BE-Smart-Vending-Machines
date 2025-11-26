# rubocop:disable Naming/VariableNumber
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should belong_to(:machine) }
    it { should have_many(:line_items).dependent(:nullify) }
    it { should have_many(:variants).through(:line_items) }
    it { should have_many(:payments).dependent(:nullify) }
  end

  describe 'validations' do
    subject { orders(:order_004) } # rubocop:disable Naming/VariableNumber
    it { should validate_presence_of(:number) }
  end

  describe 'delegations' do
    it { should delegate_method(:price_list).to(:machine).allow_nil }
    it { should delegate_method(:country).to(:machine).allow_nil }
    it { should delegate_method(:supplier).to(:machine).allow_nil }
  end

  describe 'scopes' do
    it 'returns guest orders' do
      guest_order = Order.create!(number: 'VNDG1001', machine: machines(:machine_001))
      expect(Order.guest_orders).to include(guest_order)
    end

    it 'returns user orders' do
      user_order = Order.create!(number: 'VNDG1002', machine: machines(:machine_001), user: users(:user_two))
      expect(Order.user_orders).to include(user_order)
    end

    it 'returns only cart orders' do
      cart_order = Order.create!(number: 'VNDG1003', machine: machines(:machine_001), status: 'cart')
      expect(Order.cart).to include(cart_order)
    end

    it 'returns expired carts' do
      expired = Order.create!(number: 'VNDG1004', machine: machines(:machine_001), status: 'cart',
                              created_at: 20.minutes.ago)
      expect(Order.expired_carts(10)).to include(expired)
    end
  end

  describe 'defaults' do
    it 'has default values' do
      order = Order.new
      expect(order.total).to eq(0.0)
      expect(order.items_total).to eq(0.0)
      expect(order.total_tax).to eq(0.0)
      expect(order.total_discounts).to eq(0.0)
    end
  end

  describe 'instance methods' do
    let(:order) { orders(:order_004) }

    describe '#guest_order?' do
      it 'is true when no user assigned' do
        order.update!(user: nil)
        expect(order.guest_order?).to be true
      end

      it 'is false when user assigned' do
        order.update!(user: users(:user_one))
        expect(order.guest_order?).to be false
      end
    end

    describe '#recalculate_totals!' do
      it 'updates totals based on line items' do
        order.line_items.create!(variant: variants(:pepsi_cola_12oz), quantity: 2, price: 1.50)
        order.recalculate_totals!
        expect(order.items_total).to eq(4.5)
      end
    end

    describe '#completed?' do
      it 'returns true when status is completed' do
        order.update!(status: 'completed')
        expect(order.completed?).to be true
      end
    end

    describe '#last_pending_credit_payment' do
      it 'returns the latest pending credit card payment' do
        payment = order.payments.create!(status: 'pending', payment_method: payment_methods(:credit_card), amount: 50.0)
        expect(order.last_pending_credit_payment).to eq(payment)
      end
    end
  end

  describe 'state machine' do
    let(:order) { orders(:order_004) }

    it 'starts in cart state' do
      expect(order.status).to eq('cart')
    end

    it 'can transition from cart to payment' do
      order.update!(user: users(:user_one))
      order.line_items.create!(variant: variants(:pepsi_cola_12oz), quantity: 1, price: 2.0)

      allow(Stock::Reservation).to receive(:reserve_order!).and_return(true)
      allow_any_instance_of(NotificationService::OrderNotifications).to receive(:payment_initiated)

      expect { order.start_payment! }.to change { order.reload.status }
        .from('cart').to('payment')
    end

    it 'can transition from payment to completed' do
      allow(Stock::Reservation).to receive(:commit_order!).and_return(true)
      order.update!(status: 'payment')

      expect { order.mark_completed! }.to change { order.reload.status }.from('payment').to('completed')
    end

    it 'can return to cart from payment' do
      order.update!(status: 'payment')
      expect { order.return_to_cart! }.to change { order.status }.from('payment').to('cart')
    end

    it 'can mark completed order as dispensed' do
      order.update!(status: 'completed')
      order.mark_dispensed!
      expect(order.status).to eq('dispensed')
      expect(order.dispense_status).to eq('dispensed')
    end
  end

  describe '.generate_unique_order_number' do
    it 'generates a unique order number' do
      num = Order.generate_unique_order_number
      expect(num).to match(/^VNDG\d+$/)
      expect(Order.exists?(number: num)).to be false
    end
  end
end

# rubocop:enable Naming/VariableNumber
