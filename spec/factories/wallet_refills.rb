# frozen_string_literal: true

FactoryBot.define do
  factory :wallet_refill do
    amount { 100.0 }
    status { 'pending' }
    association :wallet
    association :payment_method
  end
end
