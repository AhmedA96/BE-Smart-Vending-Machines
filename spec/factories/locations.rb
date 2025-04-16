# frozen_string_literal: true

FactoryBot.define do
  factory :location do
    name { 'Test Location' }
    address { '123 Test Street' }
    city { 'Test City' }
    state { 'Test State' }
    zip_code { '12345' }
    landmark { 'Test Landmark' }
  end
end
