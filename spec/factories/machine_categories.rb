# frozen_string_literal: true

FactoryBot.define do
  factory :machine_category do
    sequence(:name) { |n| "Category #{n}" }
    description { 'Test category description' }
  end
end
