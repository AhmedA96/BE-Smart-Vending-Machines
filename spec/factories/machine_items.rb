# frozen_string_literal: true

FactoryBot.define do
  factory :machine_item do
    association :variant
    association :machine
    stock { 10 }
  end
end
