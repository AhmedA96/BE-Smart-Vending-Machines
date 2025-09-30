# frozen_string_literal: true

json.products do
  json.array! @products do |product|
    json.partial! 'product', product: product

    total_stock = product.variants.sum { |variant| variant.machine_stock(@machine) }
    json.stock_available total_stock.positive?
    json.total_stock total_stock

    master_variant = product.variants.find(&:is_master)

    json.master_variant do
      json.extract! master_variant, :id, :name, :sku, :is_master, :max_orderable_quantity
      json.stock master_variant.machine_stock(@machine)

      if @machine&.price_list
        price_item = @machine.price_list.price_list_items.find_by(variant_id: master_variant.id)
        json.price price_item&.price
        json.currency @machine.location.country.currency
      end
    end
  end
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @products
end
