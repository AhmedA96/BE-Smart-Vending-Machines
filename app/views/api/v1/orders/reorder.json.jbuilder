# frozen_string_literal: true

json.success true
json.message @message

json.order do
  json.partial! 'api/v1/orders/order', order: @order
end

json.reorder_summary do
  json.total_original_items @reorder_summary[:total_original_items]
  json.successfully_reordered @reorder_summary[:reordered_items]
  json.unavailable_items_count @reorder_summary[:unavailable_items].size

  json.unavailable_items @reorder_summary[:unavailable_items] do |item|
    json.variant_id item[:variant_id]
    json.variant_name item[:variant_name]
    json.original_quantity item[:original_quantity]
    json.original_price item[:original_price]
    json.reason item[:reason]
  end
end
