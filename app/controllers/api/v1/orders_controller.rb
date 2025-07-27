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
        unless @order.status == 'paid'
          render json: { error: 'Order must be paid to generate pickup code' },
                 status: :unprocessable_content
          return
        end

        machine = @order.machine

        client = machine.supplier
        order_manager = Suppliers::VendlifeService.new(client)

        pickup_code = order_manager.create_pickup_order(machine, @order)
        @order.update!(pick_up_code: pickup_code)

        render json: { pickup_code: pickup_code }
      rescue SupplierApiError
        render json: { error: 'Failed to generate pickup code' }, status: :unprocessable_entity
      end

      def reorder
        result = Orders::Reorder.call(params[:id], reorder_params)
        if result[:success]
          @order = result[:order]
          @reorder_summary = {
            total_original_items: result[:total_original_items],
            reordered_items: result[:reordered_items],
            unavailable_items: result[:unavailable_items]
          }
          @message = build_reorder_message(result)
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

      def build_reorder_message(result)
        if result[:unavailable_items].empty?
          "Successfully reordered all #{result[:reordered_items]} items"
        else
          unavailable_count = result[:unavailable_items].size
          "Successfully reordered #{result[:reordered_items]} items. #{unavailable_count} items were unavailable."
        end
      end
    end
  end
end
