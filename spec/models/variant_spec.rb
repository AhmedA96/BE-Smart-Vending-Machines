# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Variant, type: :model do
  describe 'associations' do
    it { should belong_to(:product) }
  end

  describe 'validations' do
    subject { build(:variant) }

    it { should validate_presence_of(:sku) }
    it { should validate_uniqueness_of(:sku).case_insensitive }
    it { should validate_presence_of(:sorting) }
    it { should validate_numericality_of(:sorting).only_integer.is_greater_than_or_equal_to(1) }
  end
end
