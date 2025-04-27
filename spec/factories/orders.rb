# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    sequence(:number) { |n| "ORDER#{n}" }
    status { 'pending' }
    dispense_status { 'pending' }
    total { 99.99 }
    items_total { 0.0 }
    total_tax { 0.0 }
    total_discounts { 0.0 }

    association :user
    association :machine
  end
end
