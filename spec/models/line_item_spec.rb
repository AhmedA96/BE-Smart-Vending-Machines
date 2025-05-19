# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LineItem, type: :model do
  describe 'associations' do
    it { should belong_to(:order) }
    it { should belong_to(:variant) }
  end
  describe 'validations' do
    it { should validate_presence_of(:quantity) }
  end
end
