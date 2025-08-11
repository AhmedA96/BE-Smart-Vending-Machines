# frozen_string_literal: true

module LineItems
  class Update
    class << self
      def call(line_item, item_params)
        new_quantity = item_params[:quantity].to_i
        order = line_item.order

        ActiveRecord::Base.transaction do
          if new_quantity.zero?
            remove_line_item(line_item)
          else
            set_line_item_quantity(line_item, new_quantity)
          end

          order.recalculate_totals!
          order.reload
        end

        order
      end

      private

      def set_line_item_quantity(line_item, quantity)
        old_quantity = line_item.quantity
        line_item.update!(quantity: quantity)

        stock_adjustment = quantity - old_quantity
        return unless stock_adjustment != 0

        Stock::Management.call(line_item.variant_id, stock_adjustment, line_item.order.machine.id)
      end

      def remove_line_item(line_item)
        Stock::Management.call(line_item.variant_id, -line_item.quantity, line_item.order.machine.id)
        line_item.destroy!
      end
    end
  end
end
