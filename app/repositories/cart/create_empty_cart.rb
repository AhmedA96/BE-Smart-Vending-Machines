# frozen_string_literal: true

module Cart
  class CreateEmptyCart
    class << self
      def call(params)
        machine = Machine.find(params[:machine_id])
        user = User.find_by(id: params[:user_id]) if params[:user_id].present?

        if user
          existing_cart = find_existing_user_cart(user, machine)
          return existing_cart if existing_cart
        end

        Order.create!(
          number: Order.generate_unique_order_number,
          machine: machine,
          user: user,
          items_total: 0.0
        )
      end

      private

      def find_existing_user_cart(user, machine)
        Order.find_by(user: user, machine: machine, status: 'cart')
      end
    end
  end
end
