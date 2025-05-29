# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CountryTranslation, type: :model do
  describe 'associations' do
    it { should belong_to(:country) }
  end

  describe 'validations' do
    it { should validate_presence_of(:presentation) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:locale) }
  end
end
