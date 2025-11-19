# frozen_string_literal: true

json.order do
  json.partial! 'api/v1/orders/order', order: @order

  json.line_items @order.line_items.includes(:variant) do |line_item|
    json.extract! line_item, :id, :variant_id, :quantity, :price
    json.variant_name line_item.variant.presentation
    json.variant_size line_item.variant.size
    if line_item.variant.product&.images&.attached?
      json.variant_image_url url_for(line_item.variant.product.images.first)
    else
      json.variant_image_url nil
    end
    json.total line_item.quantity * line_item.price
  end
end
