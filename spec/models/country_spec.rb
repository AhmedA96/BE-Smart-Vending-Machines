# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Country, type: :model do
  describe 'associations' do
    it { should have_many(:machines) }
  end
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:iso2) }
    it { should validate_presence_of(:currency) }
  end

  describe 'enums' do
    it {
      should define_enum_for(:name).with_values({ 'UAE' => 'uae', 'KSA' => 'saudi' })
                                   .backed_by_column_of_type(:string)
    }

    it {
      should define_enum_for(:currency).with_values({ 'SAR' => 'SAR', 'AED' => 'AED' })
                                       .backed_by_column_of_type(:string)
    }
  end
end
