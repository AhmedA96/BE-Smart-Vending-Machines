# frozen_string_literal: true

json.products do
  json.array! @products do |product|
    json.partial! 'api/v1/products/product', product: product

    json.variants product.variants.available_in_machine_with_price_list(@machine) do |variant|
      json.id variant.id
      json.sku variant.sku
      json.name variant.name
      json.active variant.active
      json.presentation variant.presentation
      json.master_variant variant.is_master
      json.stock variant.machine_stock(@machine)
      json.price variant.with_price_list(@machine.location&.price_list_id)&.price
    end
  end
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @products
end
