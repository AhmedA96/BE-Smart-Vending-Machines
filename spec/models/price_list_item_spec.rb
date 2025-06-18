# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PriceListItem, type: :model do
  describe 'associations' do
    it { should belong_to(:price_list) }
    it { should belong_to(:variant) }
  end

  describe 'validations' do
    subject { price_list_items(:coke_standard_price) }

    it { should validate_presence_of(:price) }
    it { should validate_numericality_of(:price).is_greater_than(0) }
  end
end
