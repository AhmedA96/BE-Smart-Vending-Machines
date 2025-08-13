# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LineItems::Destroy do
  let(:line_item) { line_items(:order_001_coke) }
  let(:order) { line_item.order }

  before do
    allow(Stock::Management).to receive(:call)
    allow(order).to receive(:recalculate_totals!)
    allow(order).to receive(:reload).and_return(order)
  end

  describe '.call' do
    it 'removes the line item' do
      LineItems::Destroy.call(line_item)
      expect { line_item.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
