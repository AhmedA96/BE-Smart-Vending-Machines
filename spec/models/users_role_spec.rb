# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersRole, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:role) }
  end

  describe 'validations' do
    it { should validate_uniqueness_of(:user_id).scoped_to(:role_id) }
  end
end
