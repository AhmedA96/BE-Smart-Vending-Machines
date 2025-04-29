# frozen_string_literal: true

json.id machine.id
json.name machine.name
json.location machine.location&.name
json.status machine.status
json.category machine.category.name
json.category_id machine.category_id
