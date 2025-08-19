# frozen_string_literal: true

module LineItems
  class Create
    def self.call(order, item_hash)
      variant_id = item_hash[:variant_id]
      quantity_to_add = item_hash[:quantity].to_i
      variant = Variant.find(variant_id)
      machine = order.machine
      price = variant_price(machine, variant)

      ActiveRecord::Base.transaction do
        existing_item = order.line_items.find_by(variant_id: variant_id)
        line_item = if existing_item
                      new_quantity = existing_item.quantity + quantity_to_add
                      existing_item.update!(quantity: new_quantity)
                      existing_item
                    else
                      order.line_items.create!(
                        variant_id: variant_id,
                        quantity: quantity_to_add,
                        price: price
                      )
                    end

        order.recalculate_totals!

        line_item
      end
    end

    def self.variant_price(machine, variant)
      price_list_id = machine&.price_list&.id
      return 0 unless price_list_id

      find_variant_price(variant, price_list_id)
    end

    def self.find_variant_price(variant, price_list_id)
      variant.with_price_list(price_list_id)&.price.to_f
    end
  end
end
