# frozen_string_literal: true

available_variant_ids = @machine&.machine_items&.pluck(:variant_id)

json.product do
  json.partial! 'product', product: @product

  json.variants @product.variants.where(id: available_variant_ids) do |variant|
    json.id variant.id
    json.sku variant.sku
    json.name variant.name
    json.presentation variant.presentation
    json.is_master variant.is_master
    json.cost_price variant.cost_price
    json.weight variant.weight
    json.created_at variant.created_at
    json.max_orderable_quantity variant.max_orderable_quantity
    json.size variant.size
    json.stock variant.machine_stock(@machine)

    location = @machine&.location
    price_item = location&.price_list&.price_list_items&.find { |item| item.variant_id == variant.id }
    json.price price_item&.price
  end
end
