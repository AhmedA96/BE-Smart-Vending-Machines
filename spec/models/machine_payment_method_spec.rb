# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MachinePaymentMethod, type: :model do
  describe 'association' do
    it { should belong_to(:machine) }
    it { should belong_to(:payment_method) }
  end
end
