# frozen_string_literal: true

module Api
  module V1
    class OrdersController < ApplicationController
      before_action :current_user
      before_action :find_order, only: %i[show update reorder]
      before_action :authorize_order_access, only: %i[show update reorder]

      def index
        orders = policy_scope(Order)
        @orders = paginate(orders)
      end

      def show; end

      def create
        authorize Order
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

      def authorize_order_access
        authorize @order
      end

      def order_params
        params.permit(:machine_id, cart_items: %i[variant_id quantity])
              .merge(user_id: current_user&.id)
      end

      def update_params
        permitted = params.permit(cart_items: %i[variant_id quantity])
        permitted[:user_id] = current_user.id if @order.guest_order? && current_user
        permitted
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
