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
        order.lock!

        line_item = order.line_items.lock.find_or_initialize_by(variant_id: variant_id)

        if line_item.persisted?
          line_item.quantity += quantity_to_add
        else
          line_item.quantity = quantity_to_add
          line_item.price = price
        end
        line_item.save!

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
