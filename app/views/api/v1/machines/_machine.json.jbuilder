# frozen_string_literal: true

json.id machine.id
json.name machine.name
json.location machine.location&.name
json.status machine.status
json.category machine.category.name
json.category_id machine.category_id
json.floor_no machine.floor_no

if machine.image.attached?
  json.machine_image_url url_for(machine.image)
elsif machine.supplier.image.attached?
  json.supplier_image_url url_for(machine.supplier.image)
else
  json.image_url nil
end
