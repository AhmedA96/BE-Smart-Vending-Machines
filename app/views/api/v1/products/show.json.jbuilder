json.product do
  json.partial! 'product', product: @product

  json.variants @product.variants do |variant|
    json.extract! variant, :id, :name, :presentation, :sku, :is_master,
                  :cost_price, :weight, :created_at, :max_orderable_quantity, :size
  end
end
