# frozen_string_literal: true

module Orders
  class UserAttachmentService
    def initialize(guest_order, user_id)
      @guest_order = guest_order
      @user_id = user_id
    end

    def call
      user = User.find(@user_id)

      # Check if user already has a cart for this machine
      existing_user_cart = Order.find_by(
        user: user,
        machine: @guest_order.machine,
        status: 'cart'
      )

      if existing_user_cart
        # Merge guest cart items into existing user cart
        merge_cart_items(existing_user_cart, @guest_order)
        # Delete the guest cart after successful merge
        @guest_order.destroy!
        existing_user_cart.recalculate_totals!
        existing_user_cart
      else
        # Simply assign the guest cart to the user
        @guest_order.update!(user: user)
        @guest_order
      end
    end

    private

    def merge_cart_items(target_order, source_order)
      source_order.line_items.each do |source_item|
        existing_item = target_order.line_items.find_by(variant: source_item.variant)

        if existing_item
          # Check if merged quantity is valid (including stock)
          new_quantity = existing_item.quantity + source_item.quantity
          validate_merged_item(source_item.variant, new_quantity, target_order.machine)

          # Merge quantities
          existing_item.update!(quantity: new_quantity)
        else
          # Validate the item before moving it
          validate_item_for_machine(source_item, target_order.machine)

          # Move the line item to the target order
          source_item.update!(order: target_order)
        end
      end

      # Validate item limit after merging
      validate_item_limit_for_order(target_order)
    end

    def validate_merged_item(variant, quantity, machine)
      temp_item = { variant_id: variant.id, quantity: quantity }
      validate_cart_item_for_machine(temp_item, machine)
    end

    def validate_item_for_machine(source_item, machine)
      temp_item = { variant_id: source_item.variant.id, quantity: source_item.quantity }
      validate_cart_item_for_machine(temp_item, machine)
    end

    def validate_cart_item_for_machine(item, machine)
      variant_id = item[:variant_id]
      quantity = item[:quantity].to_i

      raise 'Invalid variant ID' if variant_id.blank? || !Variant.exists?(variant_id)
      raise 'Invalid quantity' if quantity.negative?

      return unless quantity.positive?

      variant = Variant.find(variant_id)

      # Check if variant is available in machine's price list
      unless machine.price_list.price_list_items.exists?(variant: variant)
        raise "Variant #{variant.name} not available for this machine"
      end

      # Validate stock
      begin
        Stock::Management.call(variant.id, quantity, machine.id)
      rescue StandardError => e
        raise "Stock validation failed for #{variant.name}: #{e.message}"
      end
    end

    def validate_item_limit_for_order(order)
      return unless order.machine.max_items_per_order

      total_items = order.line_items.sum(:quantity)
      return unless total_items > order.machine.max_items_per_order

      raise FailedRequestError.new(
        "Maximum #{order.machine.max_items_per_order} items allowed per order",
        {
          machine_id: order.machine.id,
          max_items: order.machine.max_items_per_order,
          attempted_items: total_items
        }
      )
    end
  end
end
