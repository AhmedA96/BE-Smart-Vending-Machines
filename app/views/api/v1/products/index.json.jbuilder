# frozen_string_literal: true

json.products do
  json.array! @products do |product|
    json.partial! 'product', product:
  end
end
json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @products
end
