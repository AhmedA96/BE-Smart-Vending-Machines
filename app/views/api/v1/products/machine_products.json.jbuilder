# frozen_string_literal: true

available_variant_ids = @machine.machine_items.pluck(:variant_id)
location = @machine.location
price_list_items = location&.price_list&.price_list_items || []

json.products do
  json.array! @products do |product|
    available_variants = product.variants.where(id: available_variant_ids).select do |variant|
      has_price = price_list_items.any? { |item| item.variant_id == variant.id }
      has_stock = variant.machine_stock(@machine).positive?
      has_price && has_stock
    end

    if available_variants.any?
      json.partial! 'api/v1/products/product', product: product

      json.variants available_variants do |variant|
        json.id variant.id
        json.sku variant.sku
        json.name variant.name
        json.active variant.active
        json.presentation variant.presentation
        json.master_variant variant.is_master
        json.stock variant.machine_stock(@machine)

        price_item = price_list_items.find { |item| item.variant_id == variant.id }
        json.price price_item.price
      end
    end
  end
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @products
end
