# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MachineType, type: :model do
  describe 'associations' do
    it { should have_many(:machines) }

    describe 'validations' do
      it { should validate_presence_of(:name) }
      it { should validate_presence_of(:capacity) }
    end
  end
end
