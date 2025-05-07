# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:presentation) }
  end

  describe 'associations' do
    it { should have_many(:product_categories).dependent(:destroy) }
    it { should have_many(:products).through(:product_categories) }
  end

  describe 'default values' do
    let(:category) { create(:category) }

    it 'sets active to true by default' do
      expect(category.active).to be true
    end

    it 'sets position to 0 by default' do
      expect(category.position).to eq(0)
    end
  end
end
