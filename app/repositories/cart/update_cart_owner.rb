# frozen_string_literal: true

module Cart
  class UpdateCartOwner
    def self.call(cart, user_id)
      raise FailedRequestError, 'Cart already has an owner' unless cart.guest_order?

      user = User.find(user_id)

      # Check if user already has a cart for this machine
      existing_cart = Order.find_by(user: user, machine: cart.machine, status: 'cart')

      # Destroy the old cart and attach the new guest cart to the user
      existing_cart&.destroy!

      # Assign ownership of the guest cart to the user
      cart.update!(user: user)
      cart
    end
  end
end
