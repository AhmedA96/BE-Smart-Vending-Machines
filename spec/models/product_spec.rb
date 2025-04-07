# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'associations' do
    it { should have_many(:machine_products).dependent(:destroy) }
    it { should have_many(:vending_machines).through(:machine_products) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:images) }
  end

  describe 'scopes' do
    let!(:active_product) { create(:product, is_active: true) }
    let!(:inactive_product) { create(:product, is_active: false) }

    describe '.active' do
      it 'returns only active products' do
        expect(described_class.active).to include(active_product)
        expect(described_class.active).not_to include(inactive_product)
      end
    end
  end
end
