# frozen_string_literal: true

json.items @items do |product|
  json.product_id product.id
  json.product_name product.name
  json.order_count product.order_count
  json.last_ordered product.last_ordered_by_user(@current_user)
  json.is_favorite @current_user.favorite_products.include?(product)
end
