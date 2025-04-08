# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    description { 'A detailed description of the product' }
    is_active { true }
    images { { main: 'image_url.jpg' } }
  end
end
