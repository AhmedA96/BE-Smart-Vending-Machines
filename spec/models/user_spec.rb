# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  fixtures :users

  describe 'validations' do
    it { should validate_presence_of(:mobile_number) }
  end

  describe 'password validation' do
    it 'validates password complexity' do
      user = users(:user_one)
      user.password = 'simple'
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include(I18n.t('errors.messages.password_complexity'))

      user.password = 'ValidP@ssw0rd'
      expect(user).to be_valid
    end
  end

  describe '.authenticate' do
    let(:user) { users(:user_one) }

    before do
      user.password = 'ValidP@ssw0rd'
      user.save!
    end

    it 'returns user when credentials are valid' do
      authenticated_user = described_class.authenticate(user.mobile_number, 'ValidP@ssw0rd')
      expect(authenticated_user).to eq(user)
    end

    it 'returns nil when mobile number is invalid' do
      authenticated_user = described_class.authenticate('invalid_number', 'ValidP@ssw0rd')
      expect(authenticated_user).to be_nil
    end

    it 'returns nil when password is invalid' do
      authenticated_user = described_class.authenticate(user.mobile_number, 'WrongP@ssw0rd')
      expect(authenticated_user).to be_nil
    end
  end
end
