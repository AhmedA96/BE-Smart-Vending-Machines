# frozen_string_literal: true

json.variants do
  json.array! @variants do |variant|
    json.partial! 'variant', variant:
  end
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @variants
end
