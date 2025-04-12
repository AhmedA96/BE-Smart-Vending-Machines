# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    sequence(:presentation) { |n| "Category Presentation #{n}" }
    active { true }
    position { 0 }
  end
end
