# frozen_string_literal: true

json.total_favorites @current_user.user_favorites.count

json.items @favorites do |favorite|
  product = favorite.product

  json.product_id product.id
  json.product_name product.name
  json.favorited_at favorite.created_at
  json.order_count product.order_count_for_user(@current_user)
  json.last_ordered product.last_ordered_by_user(@current_user)
end
