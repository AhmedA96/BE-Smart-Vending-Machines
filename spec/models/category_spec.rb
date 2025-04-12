# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:presentation) }
  end

  describe 'associations' do
    it { should belong_to(:parent_category).class_name('Category').optional(true) }
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

  describe 'hierarchical relationships' do
    let(:parent_category) { create(:category) }
    let(:child_category) { create(:category, parent_category: parent_category) }

    it 'allows categories to have parent categories' do
      expect(child_category.parent_category).to eq(parent_category)
    end

    it 'allows categories to exist without parent categories' do
      standalone_category = create(:category, parent_category: nil)
      expect(standalone_category.parent_category).to be_nil
    end
  end
end
