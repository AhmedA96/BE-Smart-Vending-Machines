# frozen_string_literal: true

json.order do
  json.partial! 'api/v1/orders/order', order: @order

  json.line_items @order.line_items.includes(:variant) do |line_item|
    json.extract! line_item, :id, :variant_id, :quantity, :price
    json.variant_name line_item.variant.name
    json.total line_item.quantity * line_item.price
  end
end
