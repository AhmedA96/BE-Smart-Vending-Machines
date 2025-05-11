# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'associations' do
    it { should have_many(:machines) }
    it { should have_many(:location_translations) }
  end
end
