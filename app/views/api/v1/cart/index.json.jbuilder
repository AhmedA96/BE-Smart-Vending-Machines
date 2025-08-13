# frozen_string_literal: true

json.carts do
  json.array! @carts do |cart|
    json.partial! 'cart', cart: cart
  end
end
json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @carts
end
