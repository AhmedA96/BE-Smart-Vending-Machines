# frozen_string_literal: true

module Orders
  class CreateCreditCharge < Payments::BaseCreditCharge
    def self.call(order, user)
      super(order, user, PAYMENT_OPERATION_TYPES[:order_payment])
    end
  end
end
