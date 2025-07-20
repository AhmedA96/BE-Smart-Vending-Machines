# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Address, type: :model do
  describe 'associations' do
    it { should belong_to(:country) }
    it { should belong_to(:user) }
  end
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:address) }
    it { should validate_presence_of(:appart_number) }
    it { should validate_presence_of(:building_number) }
    it { should validate_presence_of(:floor_number) }
  end
end
