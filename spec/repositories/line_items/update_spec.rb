# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LineItems::Update do
  let(:line_item) { line_items(:order_001_coke) }
  let(:order) { line_item.order }

  before do
    allow(order).to receive(:recalculate_totals!)
    allow(order).to receive(:reload).and_return(order)
  end

  describe '.call' do
    it 'updates line item quantity' do
      LineItems::Update.call(line_item, { quantity: 5 })
      expect(line_item.reload.quantity).to eq(5)
    end
  end
end
