# frozen_string_literal: true

FactoryBot.define do
  factory :line_item do
    quantity { 1 }
    unit_price { 9.99 }
    total_price { quantity * unit_price }
  end
end
