# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Variant, type: :model do
  describe 'associations' do
    it { should have_many(:machine_items) }
    it { should have_many(:machines).through(:machine_items) }
    it { should have_many(:price_lists) }
    it { should have_many(:price_lists).through(:price_list_items) }
    it { should have_many(:line_items).dependent(:nullify) }
    it { should have_many(:variant_translations) }
  end

  describe 'validations' do
    subject { build(:variant) }

    it { should validate_presence_of(:sku) }
    it { should validate_uniqueness_of(:sku).case_insensitive }
    it { should validate_presence_of(:position) }
    it { should validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(1) }
  end
end
