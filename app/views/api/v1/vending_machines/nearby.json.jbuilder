# frozen_string_literal: true

json.vending_machines @vending_machines do |machine|
  json.id machine.id
  json.name machine.name
  json.location_name machine.location_name
  json.distance machine.distance.round(2)
  json.status machine.status
  json.category machine.category.name
end

json.pagination do
  json.current_page @vending_machines.current_page
  json.total_pages @vending_machines.total_pages
  json.total_count @vending_machines.total_count
  json.next_page @vending_machines.next_page
  json.prev_page @vending_machines.prev_page
end
