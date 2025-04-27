# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Brand, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'associations' do
    it { should have_many(:products).dependent(:nullify) }
  end
end
