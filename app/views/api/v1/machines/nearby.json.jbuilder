# frozen_string_literal: true

json.machines do
  json.array! @machines do |machine|
    json.partial! 'machine', machine: machine
    json.distance machine.distance.round(2)
  end
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @machines
end
