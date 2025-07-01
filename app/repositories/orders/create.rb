# frozen_string_literal: true

module Orders
  class Create
    class << self
      def call(params)
        machine = Machine.find(params[:machine_id])
        user = User.find_by(id: params[:user_id])
        cart_items = params[:cart_items]

        validate_order_creation!(machine, user, cart_items)
        validate_item_limit!(machine, cart_items)

        ActiveRecord::Base.transaction do
          order = create_order(machine, user, cart_items)
          create_line_items(order, cart_items, machine)
          order.reload
        end
      end

      private

      def validate_order_creation!(machine, user, cart_items)
        raise 'User not found' unless user
        raise 'Machine not available' unless machine&.active?
        raise 'Machine has no price list' unless machine.price_list
        raise 'Cart items cannot be empty' if cart_items.blank?

        validate_cart_items!(cart_items)
      end

      def validate_cart_items!(cart_items)
        cart_items.each do |item|
          raise 'Invalid variant ID' if item[:variant_id].blank? || !Variant.exists?(item[:variant_id])
          raise 'Invalid quantity' unless item[:quantity].to_i.positive?
        end
      end

      def create_order(machine, user, cart_items)
        total_amount = calculate_total_amount(cart_items, machine)

        raise 'Order total cannot be zero' if total_amount <= 0

        Order.create!(
          number: Order.generate_unique_order_number,
          machine: machine,
          user: user,
          items_total: total_amount
        )
      end

      def create_line_items(order, cart_items, machine)
        cart_items.each do |item|
          LineItems::Create.call(order, item, machine)
        end
      end

      def calculate_total_amount(cart_items, machine)
        total = cart_items.sum do |item|
          variant = Variant.find(item[:variant_id])
          price = LineItems::Create.variant_price(machine, variant)

          raise "No price found for variant #{variant.name}" if price <= 0

          item[:quantity].to_i * price
        end

        total.round(2)
      end
    end

    def self.validate_item_limit!(machine, cart_items)
      return unless machine.max_items_per_order

      total_items = cart_items.sum { |item| item[:quantity].to_i }

      return unless total_items > machine.max_items_per_order

      raise FailedRequestError.new(
        "Maximum #{machine.max_items_per_order} item allowed per order",
        {
          machine_id: machine.id,
          max_items: machine.max_items_per_order,
          attempted_items: total_items
        }
      )
    end
  end
end