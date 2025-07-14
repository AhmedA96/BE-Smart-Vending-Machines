# frozen_string_literal: true

module Api
  module V1
    class OrdersController < ApplicationController
      before_action :current_user
      before_action :find_order, only: %i[show update]
      before_action :authorize_order_access, only: %i[show update]

      def index
        orders = @current_user.orders if @current_user.present?
        @orders = paginate(orders)
      end

      def show; end

      def create
        @order = Orders::Create.call(order_params)
        render :show, status: :created
      rescue StandardError => e
        raise FailedRequestError, e.message
      end

      def update
        @order = Orders::Update.call(@order.id, update_params)
        render :show, status: :ok
      rescue StandardError => e
        raise FailedRequestError, e.message
      end

      private

      def find_order
        @order = Order.find(params[:id])
      end

      def authorize_order_access
        # Allow access if:
        # 1. User owns the order
        # 2. It's a guest order (user_id is nil)
        # 3. User is authenticated and trying to claim a guest order via update
        return if @order.user_id == @current_user&.id
        return if @order.guest_order? && (action_name == 'show' || updating_guest_order?)

        raise FailedRequestError, "You don't have access to this order"
      end

      def updating_guest_order?
        action_name == 'update' && @order.guest_order? && @current_user.present?
      end

      def order_params
        permitted_params = params.permit(:machine_id, :user_id, cart_items: %i[variant_id quantity])

        # For guest users, don't include user_id if not authenticated
        permitted_params.delete(:user_id) if permitted_params[:user_id].present? && @current_user.nil?

        # If user is authenticated but no user_id provided, use current user
        permitted_params[:user_id] = @current_user.id if @current_user.present? && permitted_params[:user_id].blank?

        permitted_params
      end

      def update_params
        permitted_params = params.permit(:user_id, :payment_method, cart_items: %i[variant_id quantity])

        # If updating guest order with current user, use current user's ID
        if @order.guest_order? && @current_user.present? && permitted_params[:user_id].blank?
          permitted_params[:user_id] = @current_user.id
        end

        # Validate user_id matches current user (security check)
        if permitted_params[:user_id].present? && @current_user.present? && permitted_params[:user_id].to_i != @current_user.id # rubocop:disable Layout/LineLength
          raise FailedRequestError, 'Cannot assign order to different user'
        end

        permitted_params
      end
    end
  end
end
