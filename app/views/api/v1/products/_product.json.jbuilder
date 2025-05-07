# frozen_string_literal: true

json.extract! product, :id, :name, :description, :status,
              :max_orderable_quantity, :updated_at, :created_at
json.variants product.variants do |variant|
  json.id variant.id
  json.name variant.name
end
