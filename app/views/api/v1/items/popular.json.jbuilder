# frozen_string_literal: true

json.items @items do |variant|
  json.variant_id variant.id
  json.product_id variant.product_id
  json.product_name variant.product.name
  json.variant_name variant.presentation
  json.total_orders variant.total_orders
  json.popularity_rank @items.index(variant) + 1
end

json.cached_at Time.current
json.total @items.size
