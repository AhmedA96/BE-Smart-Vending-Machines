# frozen_string_literal: true

available_variant_ids = @machine.machine_items.pluck(:variant_id)

json.products do
  json.array! @products do |product|
    json.partial! 'api/v1/products/product', product: product

    json.variants product.variants.where(id: available_variant_ids) do |variant|
      json.id variant.id
      json.sku variant.sku
      json.name variant.name
      json.active variant.active
      json.presentation variant.presentation
      json.master_variant variant.is_master
      json.stock variant.machine_stock(@machine)

      location = @machine.location
      price_item = location&.price_list&.price_list_items&.find { |item| item.variant_id == variant.id }
      json.price price_item&.price
    end
  end
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @products
end
