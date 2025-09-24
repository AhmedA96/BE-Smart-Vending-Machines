# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    mobile_number { "+1#{Faker::Number.number(digits: 10)}" }
    password { Faker::Internet.password(min_length: 8, max_length: 20, mix_case: true, special_characters: true) }
    country
    trait :admin do
      after(:create) { |user| user.add_role(:admin) }
    end
  end
end
