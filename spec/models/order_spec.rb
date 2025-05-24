# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:machine) }
    it { should have_many(:line_items) }
    it { should have_many(:variants).through(:line_items) }
    it { should have_many(:payments) }
  end

  describe 'validations' do
    subject { build(:order) }
    it { should validate_presence_of(:number) }
  end

  describe 'attributes' do
    it 'has default values' do
      order = Order.new
      expect(order.total).to eq(0.0)
      expect(order.items_total).to eq(0.0)
      expect(order.total_tax).to eq(0.0)
      expect(order.total_discounts).to eq(0.0)
    end
  end
end
