# frozen_string_literal: true

json.extract! product, :id, :name, :description, :status, :updated_at, :created_at

location = if params[:location_id]
             Location.find_by(id: params[:location_id])
           elsif params[:machine_id]
             machine = Machine.find_by(id: params[:machine_id])
             machine.location
           end

master_variant = product.variants.find(&:is_master)

if master_variant && location&.price_list
  price_list_item = location.price_list.price_list_items.find { |item| item.variant_id == master_variant.id }

  json.master_variant_price price_list_item&.price
  json.currency location.country.currency
end

# Add images to JSON response
if product.images.attached?
  json.images(product.images.map { |image| url_for(image) })
else
  json.images []
end

# Add variants
json.variants do
  json.array! product.variants do |variant|
    json.extract! variant, :id, :name, :sku, :is_master

    # include variant price if available in location’s price list
    if location&.price_list
      price_list_item = location.price_list.price_list_items.find { |item| item.variant_id == variant.id }
      json.price price_list_item&.price
    end
  end
end
