# frozen_string_literal: true

FactoryBot.define do
  factory :vending_machine do
    manufacturer_id { 'MyString' }
    name { 'MyString' }
    category { nil }
    vendor { nil }
    location_name { 'MyString' }
    latitude { '9.99' }
    longitude { '9.99' }
    status { 'MyString' }
    installed_at { '2025-03-13 02:53:52' }
    last_service_date { '2025-03-13 02:53:52' }
  end
end
