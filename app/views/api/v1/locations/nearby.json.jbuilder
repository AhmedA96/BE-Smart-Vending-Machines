# frozen_string_literal: true

json.locations do
  json.array! @locations do |location|
    json.partial! 'location', location: location
    json.distance location.distance.round(2)
  end
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @locations
end
