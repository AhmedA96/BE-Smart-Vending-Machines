# frozen_string_literal: true

json.orders do
  json.array! @orders do |order|
    json.partial! 'order', order:
  end
end
json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @orders
end
