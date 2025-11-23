# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LocationTranslation, type: :model do
  describe 'associations' do
    it { should belong_to(:location) }
  end
  describe 'validations' do
    it { should validate_presence_of(:presentation) }
    it { should validate_presence_of(:locale) }
  end
end
