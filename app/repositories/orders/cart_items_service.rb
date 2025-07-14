# frozen_string_literal: true

module Orders
  class CartItemsService
    def initialize(order, cart_items)
      @order = order
      @cart_items = cart_items
    end

    def call
      validate_cart_items!
      process_cart_items
      remove_unlisted_items if should_remove_unlisted_items?
      validate_item_limit!
    end

    private

    def validate_cart_items!
      raise 'Machine not available' unless @order.machine&.active?
      raise 'Machine has no price list' unless @order.machine.price_list
      raise 'Cart items cannot be empty' if @cart_items.blank?

      @cart_items.each do |item|
        validate_cart_item!(item)
      end
    end

    def validate_cart_item!(item)
      variant_id = item[:variant_id]
      quantity = item[:quantity].to_i

      raise 'Invalid variant ID' if variant_id.blank? || !Variant.exists?(variant_id)
      raise 'Invalid quantity' if quantity.negative? # Allow 0 for removal

      # Skip further validation if removing item
      return unless quantity.positive?

      variant = Variant.find(variant_id)

      # Check if variant is available in machine's price list
      unless @order.machine.price_list.price_list_items.exists?(variant: variant)
        raise "Variant #{variant.name} not available for this machine"
      end

      # Validate stock
      validate_stock_for_update!(variant, quantity)
    end

    def validate_stock_for_update!(variant, new_quantity)
      Stock::Management.call(variant.id, new_quantity, @order.machine.id)
    rescue StandardError => e
      raise "Stock validation failed for #{variant.name}: #{e.message}"
    end

    def process_cart_items
      current_items = @order.line_items.includes(:variant).index_by(&:variant_id)

      @cart_items.each do |item|
        variant_id = item[:variant_id].to_i
        quantity = item[:quantity].to_i

        existing_item = current_items[variant_id]

        if quantity.positive?
          if existing_item
            update_existing_item(existing_item, quantity)
          else
            # Create new line item using the same service as Orders::Create
            LineItems::Create.call(@order, item, @order.machine)
          end
        elsif existing_item
          remove_existing_item(existing_item)
        end
      end
    end

    def update_existing_item(existing_item, new_quantity)
      quantity_diff = new_quantity - existing_item.quantity

      return unless quantity_diff != 0

      # Validate stock for the new quantity
      validate_stock_for_update!(existing_item.variant, new_quantity)

      # Update the quantity
      existing_item.update!(quantity: new_quantity)

      # Handle stock management for the difference
      return unless quantity_diff.positive?

      Stock::Management.call(existing_item.variant_id, quantity_diff, @order.machine.id)
    end

    def remove_existing_item(existing_item)
      # Release the stock back when removing
      Stock::Management.call(existing_item.variant_id, -existing_item.quantity, @order.machine.id)
      existing_item.destroy!
    end

    def remove_unlisted_items
      updated_variant_ids = @cart_items.map { |item| item[:variant_id].to_i }
      items_to_remove = @order.line_items.where.not(variant_id: updated_variant_ids)

      # Release stock for removed items
      items_to_remove.each do |item|
        Stock::Management.call(item.variant_id, -item.quantity, @order.machine.id)
      end

      items_to_remove.destroy_all
    end

    def validate_item_limit!
      return unless @order.machine.max_items_per_order

      total_items = @order.line_items.sum(:quantity)
      return unless total_items > @order.machine.max_items_per_order

      raise FailedRequestError.new(
        "Maximum #{@order.machine.max_items_per_order} items allowed per order",
        {
          machine_id: @order.machine.id,
          max_items: @order.machine.max_items_per_order,
          attempted_items: total_items
        }
      )
    end

    def should_remove_unlisted_items?
      false
    end
  end
end
