# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MachineCategory, type: :model do
  describe 'associations' do
    it { should have_many(:machines) }
    it { should have_many(:machine_category_translations) }
  end

  describe 'validations' do
    subject { machine_categories(:snack_machines) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end
end
