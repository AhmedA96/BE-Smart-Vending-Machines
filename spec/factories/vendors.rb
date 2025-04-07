# frozen_string_literal: true

FactoryBot.define do
  factory :vendor do
    sequence(:name) { |n| "Vendor #{n}" }
    sequence(:contact_person) { |n| "Contact Person #{n}" }
    sequence(:phone_number) { |n| "+1234567890#{n}" }
    sequence(:email) { |n| "vendor#{n}@example.com" }
    address { '123 Test Street, Test City' }
  end
end
