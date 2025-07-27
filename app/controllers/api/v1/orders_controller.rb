# frozen_string_literal: true

module Api
  module V1
    class OrdersController < ApplicationController
      before_action :current_user
      before_action :find_order, only: %i[show create_pickup_code]

      def index
        orders = (@current_user.orders if @current_user.present?)
        @orders = paginate(orders)
      end

      def show; end

      def create
        @order = Orders::Create.call(order_params)
        render :show, status: :created
      rescue StandardError => e
        raise FailedRequestError, e.message
      end

      def create_pickup_code
        result = Orders::CreatePickupCode.call(@order)

        if result[:success]
          render json: { pickup_code: result[:pickup_code] }
        else
          render json: { error: result[:error] }, status: result[:status]
        end
      end

      def reorder
        result = Orders::Reorder.call(params[:id], reorder_params)

        if result[:success]
          @order = result[:order]
          @reorder_info = result
          render :reorder, status: :created
        else
          @errors = result[:errors]
          render 'shared/errors', status: :unprocessable_entity
        end
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

      def reorder_params
        params.permit(:machine_id, :user_id)
      end
    end
  end
end
