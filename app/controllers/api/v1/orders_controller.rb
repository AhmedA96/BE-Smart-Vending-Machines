# frozen_string_literal: true

module Api
  module V1
    class OrdersController < ApplicationController
      before_action :current_user
      before_action :find_order, only: %i[show reorder checkout status]
      before_action :authorize_order_access, only: %i[show reorder]

      def index
        orders = policy_scope(Order)
        @orders = paginate(
          orders.completed
                .includes(:machine)
                .order(completed_at: :desc)
        )
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
        if Rails.env.production? && !@order.ensure_machine_online?
          render json: { errors: I18n.t('orders.errors.machine_offline') },
                 status: :unprocessable_content
          return
        end

        @order.process_payment!
        render :show, status: :ok
      end

      def status
        unless Rails.env.production?
          render json: { order_number: @order.number, status: 'ready',
                         message: 'Order is ready to be dispensed (mocked)' }
          return
        end

        status_data = Orders::CheckOrderStatus.call(@order)
        render json: { order_number: @order.number, status: status_data }
      rescue SupplierApiError
        render json: { error: 'Failed to check order status' }, status: :unprocessable_content
      end

      private

      def find_order
        @order = Order.find(params[:id])
      end

      def authorize_order_access
        authorize @order
      end
    end
  end
end
