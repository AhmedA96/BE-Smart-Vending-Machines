# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BrandTranslation, type: :model do
  describe 'associations' do
    it { should belong_to(:brand) }
  end
  describe 'validations' do
    it { should validate_presence_of(:locale) }
    it { should validate_presence_of(:presentation) }
  end
end
