# frozen_string_literal: true

module Suppliers
  class CreateMachineOrderJob < ApplicationJob
    queue_as :suppliers
    retry_on StandardError, wait: :exponentially_longer, attempts: 3

    def perform(order_id)
      order = Order.find_by(id: order_id)
      return unless order

      Suppliers::CreateMachineOrder.new(order).call
    end
  end
end
