# frozen_string_literal: true

json.extract! product, :id, :name, :description, :status,
              :max_orderable_quantity, :updated_at, :created_at

master_variant = product.variants.find(&:is_master)
if master_variant && @machine&.location&.price_list
  price_list_item = @machine.location.price_list.price_list_items.find { |item| item.variant_id == master_variant.id }
  json.master_variant_price price_list_item&.price
  json.currency @machine.country.currency
end

# Add images to JSON response
if product.images.attached?
  json.images(product.images.map { |image| url_for(image) })
else
  json.images []
end
