# frozen_string_literal: true

module Orders
  class Update
    class << self
      def call(order_id, params)
        order = Order.find(order_id)

        raise 'Cannot update order that is not in cart status' unless order.cart?

        ActiveRecord::Base.transaction do
          # Handle cart items updates first (if provided)
          CartItemsService.new(order, params[:cart_items]).call if params[:cart_items].present?

          # Handle attaching guest cart to user
          if params[:user_id].present? && order.user_id.nil?
            order = UserAttachmentService.new(order, params[:user_id]).call
          else
            update_order_attributes(order, params)
          end

          # Recalculate totals after all updates
          order.recalculate_totals! if params[:cart_items].present?
        end

        order.reload
      end

      private

      def update_order_attributes(order, params)
        permitted_params = params.except(:cart_items).slice(:user_id, :payment_method)

        if permitted_params[:user_id].present?
          permitted_params[:user] = User.find(permitted_params[:user_id])
          permitted_params.delete(:user_id)
        end

        order.update!(permitted_params)
      end
    end
  end
end
