# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VariantTranslation, type: :model do
  describe 'associations' do
    it { should belong_to(:variant) }
  end
  describe 'validations' do
    it { should validate_presence_of(:presentation) }
    it { should validate_presence_of(:locale) }
  end
end
