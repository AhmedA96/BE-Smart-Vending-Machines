# frozen_string_literal: true

module Api
  module V1
    class OrdersController < ApplicationController
      before_action :current_user
      before_action :find_order, only: %i[show]

      def index
        orders = (@current_user.orders if @current_user.present?)
        @orders = paginate(orders)
      end

      def show; end

      def create
        @order = Orders::Create.call(order_params)
        render :show, status: :created
      end

      private

      def find_order
        @order = Order.find(params[:id])
      end

      def order_params
        params.except(order: [
                        :'cart_items:', :'%i[', :variant_id, :quantity, :']'
                      ])
      end
    end
  end
end
