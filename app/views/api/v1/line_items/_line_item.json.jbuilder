# frozen_string_literal: true

json.id line_item.id
json.quantity line_item.quantity
json.price line_item.price
json.price_after_discount line_item.price_after_discount
json.updated_at line_item.created_at
json.created_at line_item.created_at

json.variant do
  json.partial! 'api/v1/variants/variant', variant: line_item.variant, machine: line_item&.order&.machine
  json.price line_item.variant.with_price_list(price_list&.id)&.price
  json.currency @cart.country.currency
end
