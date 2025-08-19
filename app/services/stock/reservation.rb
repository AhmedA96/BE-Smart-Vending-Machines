# frozen_string_literal: true

module Stock
  class Reservation
    class << self
      def reserve_order!(order)
        order.line_items.find_each do |line_item|
          reserve!(order.machine, line_item.variant, line_item.quantity)
        end
      end

      def commit_order!(order)
        order.line_items.find_each do |line_item|
          commit!(order.machine, line_item.variant, line_item.quantity)
        end
      end

      def release_order!(order)
        order.line_items.find_each do |line_item|
          release!(order.machine, line_item.variant, line_item.quantity)
        end
      end

      def reserve!(machine, variant, quantity)
        machine_item = MachineItem.find_by!(machine: machine, variant: variant)
        available = (machine_item.stock || 0) - (machine_item.reserved_stock || 0)
        raise FailedRequestError, 'Insufficient stock for one or more items' if available < quantity.to_i

        machine_item.update!(reserved_stock: (machine_item.reserved_stock || 0) + quantity.to_i)
      end

      def commit!(machine, variant, quantity)
        machine_item = MachineItem.find_by!(machine: machine, variant: variant)
        new_reserved = (machine_item.reserved_stock || 0) - quantity.to_i
        new_stock = (machine_item.stock || 0) - quantity.to_i
        raise FailedRequestError, 'Stock commit underflow' if new_reserved.negative? || new_stock.negative?

        machine_item.update!(reserved_stock: new_reserved, stock: new_stock)
      end

      def release!(machine, variant, quantity)
        machine_item = MachineItem.find_by!(machine: machine, variant: variant)
        current_reserved = machine_item.reserved_stock || 0
        release_qty = [quantity.to_i, current_reserved].min
        return if release_qty <= 0

        machine_item.update!(reserved_stock: current_reserved - release_qty)
      end
    end
  end
end
