# frozen_string_literal: true

FactoryBot.define do
  factory :payment_method do
    # Add default attributes for payment_method factory
    name { 'credit' }
    active { true }
  end
end
