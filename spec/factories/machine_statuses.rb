# frozen_string_literal: true

FactoryBot.define do
  factory :machine_status do
    machine { nil }
    status { 'MyString' }
    changed_at { '2025-03-13 03:02:21' }
    notes { 'MyText' }
  end
end
