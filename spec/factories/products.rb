# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    sequence(:slug) { |n| "product-#{n}" }
    description { 'A detailed description of the product' }
    status { 'Active' }
    total_rate { rand(0.0..5.0).round(1) }
    max_orderable_quantity { rand(1..100) }
    sorting { 1 }
    deleted_at { nil }

    after(:create) do |product|
      create_list(:variant, 3, product: product)
    end
  end
end
