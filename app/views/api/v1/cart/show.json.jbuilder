# frozen_string_literal: true

json.cart do
  json.partial! 'api/v1/cart/cart', cart: @cart
  json.line_items @cart.line_items.includes(:variant).order(:created_at) do |line_item|
    json.extract! line_item, :id, :variant_id, :quantity, :price
    json.variant_name line_item.variant.name
    json.variant_size line_item.variant.size
    if line_item.variant.product&.images&.attached?
      json.variant_image_url url_for(line_item.variant.product.images.first)
    else
      json.variant_image_url nil
    end
    json.total line_item.quantity * line_item.price
  end
end
