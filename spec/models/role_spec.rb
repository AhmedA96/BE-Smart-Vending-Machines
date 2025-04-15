# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'associations' do
    it { should have_many(:users_roles) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end
end
