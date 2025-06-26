# frozen_string_literal: true

json.extract! product, :id, :name, :description, :status,
              :max_orderable_quantity, :updated_at, :created_at

master_variant = product.variants.find(&:is_master)
if master_variant && @machine&.location&.price_list
  price_list_item = @machine.location.price_list.price_list_items.find { |item| item.variant_id == master_variant.id }
  json.master_variant_price price_list_item&.price
end
