# frozen_string_literal: true

module Orders
  class Reorder
    class << self
      def call(original_order_id, params = {})
        original_order = Order.find(original_order_id)
        machine = find_machine(params, original_order)
        user = find_user(params, original_order)

        validate_reorder_eligibility!(original_order, machine)

        cart_items = build_cart_items_from_order(original_order, machine)

        return { success: false, errors: ['No available items to reorder'] } if cart_items.empty?

        ActiveRecord::Base.transaction do
          new_order = Orders::Create.call(
            machine_id: machine.id,
            user_id: user.id,
            cart_items: cart_items
          )

          {
            success: true,
            order: new_order,
            unavailable_items: unavailable_items_info,
            reordered_items: cart_items.size,
            total_original_items: original_order.line_items.size
          }
        end
      rescue ActiveRecord::RecordNotFound => e
        { success: false, errors: ["Record not found: #{e.message}"] }
      rescue FailedRequestError => e
        { success: false, errors: [e.message] }
      end

      private

      def find_machine(params, original_order)
        if params[:machine_id].present?
          Machine.find(params[:machine_id])
        else
          original_order.machine
        end
      end

      def find_user(params, original_order)
        if params[:user_id].present?
          User.find(params[:user_id])
        else
          original_order.user
        end
      end

      def validate_reorder_eligibility!(original_order, machine)
        raise 'Original order not found' unless original_order
        raise 'Machine not available' unless machine&.active?
        raise 'Original order has no line items' if original_order.line_items.empty?
        raise 'Machine has no price list' unless machine.price_list
      end

      def build_cart_items_from_order(original_order, machine)
        @unavailable_items = []

        original_order.line_items.filter_map do |line_item|
          variant = line_item.variant

          if variant_available_for_reorder?(variant, machine, line_item.quantity)
            {
              variant_id: variant.id,
              quantity: line_item.quantity
            }
          else
            track_unavailable_item(line_item, variant, machine)
            nil
          end
        end
      end

      def variant_available_for_reorder?(variant, machine, quantity)
        return false unless variant&.active?
        return false unless variant_exists_on_machine?(variant, machine)
        return false unless sufficient_stock_available?(variant, machine, quantity)
        return false unless variant_has_price?(variant, machine)

        true
      end

      def variant_exists_on_machine?(variant, machine)
        machine.machine_items.exists?(variant: variant)
      end

      def sufficient_stock_available?(variant, machine, quantity)
        stock_quantity = variant.machine_stock(machine)
        stock_quantity.to_i >= quantity.to_i
      end

      def variant_has_price?(variant, machine)
        price = LineItems::Create.variant_price(machine, variant)
        price.positive?
      end

      def track_unavailable_item(line_item, variant, machine)
        @unavailable_items ||= []
        @unavailable_items << {
          variant_id: variant&.id,
          variant_name: variant&.name || 'Unknown Item',
          original_quantity: line_item.quantity,
          original_price: line_item.price,
          reason: determine_unavailability_reason(variant, machine, line_item.quantity)
        }
      end

      def determine_unavailability_reason(variant, machine, quantity)
        return 'Item no longer exists' unless variant
        return 'Item is inactive' unless variant.active?
        return 'Item not available on this machine' unless variant_exists_on_machine?(variant, machine)
        return 'No price available for this machine' unless variant_has_price?(variant, machine)

        stock_quantity = variant.machine_stock(machine)
        if stock_quantity.to_i < quantity.to_i
          return "Insufficient stock (available: #{stock_quantity}, requested: #{quantity})"
        end

        'Item temporarily unavailable'
      end

      def unavailable_items_info
        @unavailable_items || []
      end
    end
  end
end
