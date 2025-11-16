# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentMethodTranslation, type: :model do
  describe 'associations' do
    it { should belong_to(:payment_method) }
  end
  describe 'validations' do
    it { is_expected.to validate_presence_of(:locale) }
  end
end
