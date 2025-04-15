# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MachineStatus, type: :model do
  it { should belong_to(:vending_machine) }
  it { should validate_presence_of(:status) }
  it { should validate_inclusion_of(:status).in_array(%w[Active Inactive Maintenance Retired]) }
end
