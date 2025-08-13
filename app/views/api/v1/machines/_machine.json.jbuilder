# frozen_string_literal: true

json.id machine.id
json.name machine.name
json.location machine.location&.name
json.status machine.status
json.stocked machine.stocked?
json.category machine.category.name
json.category_id machine.category_id
json.floor_no machine.floor_no
json.machine_type machine.machine_type&.name
json.location_id machine.location_id
json.image do
  if machine.image.attached?
    json.url url_for(machine.image)
  else
    json.url nil
  end
end
json.supplier do
  if machine.supplier.image.attached?
    json.image url_for(machine.supplier.image)
  else
    json.image nil
  end
end
