# frozen_string_literal: true

FactoryBot.define do
  factory :variant do
    sku { Faker::Alphanumeric.alphanumeric(number: 10) }
    is_master { false }
    product
    name { Faker::Name.name }
    weight { Faker::Number.decimal(l_digits: 2) }
  end
end
