# frozen_string_literal: true

json.items @items do |variant|
  json.variant_id variant.id
  json.product_id variant.product_id
  json.product_name variant.product.name
  json.variant_name variant.presentation
  json.recent_orders variant.recent_orders
  json.trend_rank @items.index(variant) + 1
end

json.period "Last #{@days} day(s)"
json.cached_at Time.current
json.total @items.size
