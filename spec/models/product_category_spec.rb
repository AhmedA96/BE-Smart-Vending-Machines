# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProductCategory, type: :model do
  describe 'associations' do
    it { should belong_to(:product).required }
    it { should belong_to(:category).required }
  end

  describe 'validations' do
    subject { product_categories(:beverages_snacks) }
    it { should validate_uniqueness_of(:product_id).scoped_to(:category_id) }
  end
end
