# frozen_string_literal: true

FactoryBot.define do
  factory :machine do
    sequence(:machineuuid) { |n| "MAN#{n.to_s.rjust(4, '0')}" }
    sequence(:name) { |n| "Machine #{n}" }
    association :category, factory: :machine_category
    association :vendor
    association :location
    association :supplier
    status { 'Active' }
    installed_at { Time.current }
    last_service_date { Time.current }
    coordinates { 'POINT(1.234 5.678)' }
    location_updated_at { Time.current }
  end
end
