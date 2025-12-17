# frozen_string_literal: true

module Api
  module V1
    class LineItemsController < ApplicationController
      before_action :current_user
      before_action :find_cart
      before_action :find_line_item, only: %i[update destroy]
      before_action :authorize_cart_access

      def create
        @line_item = LineItems::Create.call(@cart, line_item_params)
        render :show, status: :created
      end

      def update
        LineItems::Update.call(@line_item, update_params)
        @line_items = @cart.line_items.includes(variant: :product).order(:created_at)

        render 'api/v1/cart/show', status: :ok
      end

      def destroy
        LineItems::Destroy.call(@line_item)
        render 'api/v1/cart/show', status: :ok
      end

      private

      def line_item_params
        params.expect(line_item: %i[variant_id quantity])
      end

      def update_params
        params.expect(line_item: [:quantity])
      end

      def find_cart
        @cart = Order.find(params[:cart_id])
      end

      def find_line_item
        @line_item = @cart.line_items.find(params[:id])
      end

      def authorize_cart_access
        return if @cart.guest_order? || (@cart.user == current_user)

        raise FailedRequestError, 'You are not authorized to access this cart'
      end
    end
  end
end
