# frozen_string_literal: true

json.success true
json.message "Successfully created new cart with #{@new_cart.line_items.count} items from your previous order"

json.new_cart do
  json.partial! 'api/v1/orders/order', order: @new_cart
end

json.original_order do
  json.id @order.id
  json.number @order.number
  json.total_items @order.line_items.count
end
