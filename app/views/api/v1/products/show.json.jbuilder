# frozen_string_literal: true

available_variant_ids = @machine&.machine_items&.pluck(:variant_id)

json.product do
  json.partial! 'product', product: @product

  json.variants @product.variants.where(id: available_variant_ids) do |variant|
    json.extract! variant, :id, :sku, :name, :presentation, :is_master,
                  :cost_price, :weight, :created_at, :max_orderable_quantity, :size

    json.stock variant.machine_stock(@machine)

    if @machine&.price_list
      price_item = @machine.price_list.price_list_items.find_by(variant_id: variant.id)
      json.price price_item&.price
      json.currency @machine.location.country.currency
    end
  end
end
