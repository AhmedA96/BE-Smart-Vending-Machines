# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactUsRequest, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:phone_number) }
    it { should validate_presence_of(:full_name) }
    it { should validate_presence_of(:company_name) }
  end
end
