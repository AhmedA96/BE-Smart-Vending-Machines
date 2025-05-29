# frozen_string_literal: true

FactoryBot.define do
  factory :country do
    name { 'UAE' }
    iso2 { 'AE' }
    currency { 'AED' }
    time_zone { 'Abu Dhabi' }
  end
end
