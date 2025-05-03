# frozen_string_literal: true

json.categories do
  json.array! @categories do |category|
    json.partial! 'category', category:
  end
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @categories
end
