# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    # Add basic attributes for Order factory
    sequence(:order_number) { |n| "ORDER#{n}" }
    status { 'pending' }
    total_amount { 99.99 }
    
    association :user
  end
end
