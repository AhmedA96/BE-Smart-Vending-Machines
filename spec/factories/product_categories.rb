# frozen_string_literal: true

FactoryBot.define do
  factory :product_category do
    association :product
    association :category
  end
end
