# frozen_string_literal: true

json.items @items do |variant|
  json.variant_id variant.id
  json.product_id variant.product_id
  json.product_name variant.product.name
  json.variant_name variant.name
  json.order_count variant.order_count
  json.last_ordered variant.last_ordered_by_user(@current_user)
  json.is_favorite @current_user.favorite_variants.include?(variant)
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @items
end
