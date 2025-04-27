# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end
  describe 'validations' do
    it { should validate_presence_of(:number) }
    it { should validate_presence_of(:status) }
  end
end
