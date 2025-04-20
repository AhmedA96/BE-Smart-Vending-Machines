# frozen_string_literal: true

json.vending_machines @vending_machines do |machine|
  json.id machine.id
  json.name machine.name
  json.location machine.location&.name
  json.distance machine.distance.round(2)
  json.status machine.status
  json.category machine.category.name
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @vending_machines
end
