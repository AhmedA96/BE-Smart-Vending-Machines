# frozen_string_literal: true

json.favorites @favorites do |favorite|
  product = favorite.product

  json.product_id product.id
  json.product_name product.name
  json.favorited_at favorite.created_at
  json.order_count product.order_count_for_user(@current_user)
  json.last_ordered product.last_ordered_by_user(@current_user)

  if product.images.attached?
    json.images(product.images.map { |image| url_for(image) })
  else
    json.images []
  end
end
