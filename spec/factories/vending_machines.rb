# frozen_string_literal: true

FactoryBot.define do
  factory :vending_machine do
    sequence(:manufacturer_id) { |n| "MAN#{n.to_s.rjust(4, '0')}" }
    sequence(:name) { |n| "Vending Machine #{n}" }
    association :category, factory: :machine_category
    association :vendor
    association :location
    status { 'Active' }
    installed_at { Time.current }
    last_service_date { Time.current }
    coordinates { 'POINT(1.234 5.678)' }
    location_updated_at { Time.current }
  end
end
