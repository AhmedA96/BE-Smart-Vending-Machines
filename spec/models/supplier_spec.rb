# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Supplier, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:app_id) }
    it { should validate_presence_of(:app_secret) }
  end
end
