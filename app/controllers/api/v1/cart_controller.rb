# frozen_string_literal: true

module Api
  module V1
    class CartController < ApplicationController
      before_action :current_user
      before_action :find_cart, only: %i[show update_owner]
      before_action :authorize_cart_access, only: %i[show update_owner]

      def index
        carts = policy_scope(Order)
        @carts = paginate(carts.cart)
      end

      def show
        @cart.recalculate_totals!
        @line_items = @cart.line_items.includes(variant: :product).order(:created_at)
      end

      def create
        @cart = Cart::CreateEmptyCart.call(cart_params)
        @line_items = @cart.line_items.includes(variant: :product).order(:created_at)
        render :show, status: :created
      end

      def update_owner
        @cart = Cart::UpdateCartOwner.call(@cart, current_user&.id)
        render :show, status: :ok
      end

      private

      def cart_params
        params.permit(:machine_id).merge(user_id: current_user&.id)
      end

      def find_cart
        @cart = Order.find(params[:id])
      end

      def authorize_cart_access
        return if @cart.guest_order? || (@cart.user == current_user)

        raise FailedRequestError, 'You are not authorized to access this cart'
      end
    end
  end
end
