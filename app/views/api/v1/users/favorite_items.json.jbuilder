# frozen_string_literal: true

json.total_favorites @current_user.user_favorites.count

json.items @favorites do |favorite|
  variant = favorite.variant

  json.variant_id variant.id
  json.product_id variant.product_id
  json.product_name variant.product.name
  json.variant_name variant.name
  json.favorited_at favorite.created_at
  json.order_count variant.order_count_for_user(@current_user)
  json.last_ordered variant.last_ordered_by_user(@current_user)
end
