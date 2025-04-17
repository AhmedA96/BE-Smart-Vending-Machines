# frozen_string_literal: true

FactoryBot.define do
  factory :price_list_item do
    association :price_list
    association :variant
    price { 100 }
  end
end
