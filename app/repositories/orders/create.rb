# frozen_string_literal: true

module Orders
  class Create
    def self.call(params)
      machine = Machine.find(params[:machine_id])
      user = User.find_by(id: params[:user_id])
      cart_items = params[:cart_items]

      ActiveRecord::Base.transaction do
        order = create_order(machine, user, cart_items)
        create_line_items(order, cart_items, machine)
        order
      end
    end

    def self.create_order(machine, user, cart_items)
      Order.create!(
        number: Order.generate_unique_order_number,
        machine: machine,
        user: user,
        items_total: calculate_total_amount(cart_items, machine)
      )
    end

    def self.create_line_items(order, cart_items, machine)
      cart_items.each do |item|
        LineItems::Create.call(order, item, machine)
      end
    end

    def self.calculate_total_amount(cart_items, machine)
      cart_items.sum do |item|
        variant = Variant.find(item[:variant_id])
        price = LineItems::Create.variant_price(machine, variant)
        item[:quantity].to_i * price
      end
    end
  end
end
