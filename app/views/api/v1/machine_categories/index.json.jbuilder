# frozen_string_literal: true

json.machine_categories do
  json.array! @machine_categories do |machine_category|
    json.partial! 'machine_category', machine_category: machine_category
  end
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @machine_categories
end
