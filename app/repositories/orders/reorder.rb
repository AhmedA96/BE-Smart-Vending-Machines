# frozen_string_literal: true

module Orders
  class Reorder
    class << self
      def call(original_order)
        machine = original_order.machine
        user = original_order.user
        raise FailedRequestError, 'Machine not available' unless machine&.active?

        ActiveRecord::Base.transaction do
          new_order = Order.create!(
            user: user,
            machine: machine,
            number: Order.generate_unique_order_number
          )

          copy_line_items(original_order, new_order)
          new_order.recalculate_totals!

          new_order
        end
      end

      private

      def copy_line_items(original_order, new_order)
        original_order.line_items.each do |item|
          copy_line_item(item, new_order)
        end
      end

      def copy_line_item(item, new_order)
        price = LineItems::Create.variant_price(new_order.machine, item.variant)

        new_order.line_items.create!(
          variant: item.variant,
          quantity: item.quantity,
          price: price
        )
      end
    end
  end
end
