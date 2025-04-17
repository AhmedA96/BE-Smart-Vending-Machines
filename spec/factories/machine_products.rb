# frozen_string_literal: true

FactoryBot.define do
  factory :machine_product do
    association :variant
    association :vending_machine
    stock { 10 }
  end
end
