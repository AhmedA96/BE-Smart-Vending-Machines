# frozen_string_literal: true

module LineItems
  class Create
    def self.call(order, item_hash, machine)
      line_item = order.line_items.create!(
        variant_id: item_hash[:variant_id],
        quantity: item_hash[:quantity],
        price: variant_price(machine, Variant.find(item_hash[:variant_id]))
      )

      Stock::Management.call(
        item_hash[:variant_id],
        item_hash[:quantity],
        machine.id
      )

      line_item
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
