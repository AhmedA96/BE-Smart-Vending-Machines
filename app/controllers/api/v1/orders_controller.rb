# frozen_string_literal: true

module Api
  module V1
    class OrdersController < ApplicationController
      before_action :current_user
      before_action :find_order, only: %i[show reorder]
      before_action :authorize_order_access, only: %i[show reorder]
      before_action :find_cart, only: %i[checkout]

      def index
        orders = policy_scope(Order)
        @orders = paginate(orders.completed)
      end

      def show
        if @order.completed?
          render :show
        else
          render json: [], status: :ok
        end
      end

      def reorder
        @new_cart = Orders::Reorder.call(@order)
        render :reorder, status: :created
      end

      def checkout
        @cart.process_payment!

        render json: { order_id: @cart.id, total: @cart.items_total }
      end

      private

      def find_order
        @order = Order.find(params[:id])
      end

      def authorize_order_access
        authorize @order
      end

      def find_cart
        @cart = current_user.orders.find(params[:id])
      end
    end
  end
end
