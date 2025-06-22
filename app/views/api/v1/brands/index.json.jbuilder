# frozen_string_literal: true

json.brands do
  json.array! @brands do |brand|
    json.partial! 'brand', brand:
  end
end
json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @brands
end
