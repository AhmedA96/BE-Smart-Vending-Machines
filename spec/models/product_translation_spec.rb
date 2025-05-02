# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProductTranslation, type: :model do
  describe 'associations' do
    it { should belong_to(:product) }
  end

  describe 'validations' do
    subject { build(:product_translation) }

    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:locale) }
  end
end
