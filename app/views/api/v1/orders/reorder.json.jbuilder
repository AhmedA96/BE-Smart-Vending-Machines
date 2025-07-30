# frozen_string_literal: true

json.success true

if @reorder_info[:unavailable_items].empty?
  json.message "Successfully reordered all #{@reorder_info[:reordered_items]} items"
else
  unavailable_count = @reorder_info[:unavailable_items].size
  json.message "Successfully reordered #{@reorder_info[:reordered_items]} items. #{unavailable_count} items were unavailable." # rubocop:disable Layout/LineLength
end

json.order do
  json.partial! 'api/v1/orders/order', order: @order
end

json.reorder_summary do
  json.total_original_items @reorder_info[:total_original_items]
  json.successfully_reordered @reorder_info[:reordered_items]
  json.unavailable_items_count @reorder_info[:unavailable_items].size
  json.unavailable_items @reorder_info[:unavailable_items] do |item|
    json.variant_id item[:variant_id]
    json.variant_name item[:variant_name]
    json.original_quantity item[:original_quantity]
    json.original_price item[:original_price]
    json.reason item[:reason]
  end
end
