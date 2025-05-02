# frozen_string_literal: true

FactoryBot.define do
  factory :product_translation do
    description { 'Sample product description' }
    presentation { 'Sample presentation' }
    locale { 'en' }

    association :product
  end
end
