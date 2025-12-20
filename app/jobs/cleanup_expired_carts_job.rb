# frozen_string_literal: true

class CleanupExpiredCartsJob < ApplicationJob
  queue_as :default

  def perform(timeout_minutes: 30)
    expired_orders = Order.expired_carts(timeout_minutes)

    Rails.logger.info "Cleaning up #{expired_orders.count} expired carts"

    expired_orders.find_each do |order|
      cleanup_cart(order)
    end
  end

  private

  def cleanup_cart(order)
    Rails.logger.info "Cleaning up expired cart: #{order.id}"

    ActiveRecord::Base.transaction do
      release_reservations(order)

      order.line_items.delete_all

      order.destroy!
    end
  rescue StandardError => e
    Rails.logger.error "Failed to cleanup cart #{order.id}: #{e.message}"
  end

  def release_reservations(order)
    Stock::Reservation.release_order!(order)
  rescue StandardError => e
    Rails.logger.warn "Failed to release reservations for order #{order.id}: #{e.message}"
  end
end
