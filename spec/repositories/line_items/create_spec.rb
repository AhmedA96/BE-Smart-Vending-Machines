# rubocop:disable Naming/VariableNumber
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LineItems::Create do
  let(:order) { orders(:order_001) }
  let(:variant) { variants(:coke_classic_12oz) }

  before do
    allow(order).to receive(:recalculate_totals!)
  end

  describe '.call' do
    it 'creates new line item with correct quantity' do
      order.line_items.where(variant_id: variant.id).destroy_all
      params = { variant_id: variant.id, quantity: 3 }

      expect do
        LineItems::Create.call(order, params)
      end.to change(order.line_items, :count).by(1)

      line_item = order.line_items.find_by(variant_id: variant.id)
      expect(line_item.quantity).to eq(3)
      expect(line_item.variant_id).to eq(variant.id)
    end
  end
end

# rubocop:enable Naming/VariableNumber
