# frozen_string_literal: true

module Cart
  class UpdateCartOwner
    def self.call(cart, user_id)
      raise FailedRequestError, 'Cart already has an owner' unless cart.guest_order?

      user = User.find(user_id)
      cart.update!(user: user)
      cart
    end
  end
end
