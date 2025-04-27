# frozen_string_literal: true

FactoryBot.define do
  factory :brand do
    name { 'Sample Brand' }
    description { 'This is a sample brand description.' }
    logo { 'sample_logo.png' }
    background { 'sample_background.png' }
  end
end
