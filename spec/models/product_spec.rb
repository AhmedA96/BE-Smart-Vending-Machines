# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'associations' do
    it { should have_many(:machine_products).dependent(:destroy) }
    it { should have_many(:vending_machines).through(:machine_products) }
    it { should have_many(:variants).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[Active Inactive]) }
    it { should validate_numericality_of(:max_orderable_quantity).is_greater_than(0).allow_nil }
    it { should validate_presence_of(:sorting) }
    it { should validate_numericality_of(:sorting).only_integer.is_greater_than_or_equal_to(1) }
  end
end
