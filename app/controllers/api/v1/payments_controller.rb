# frozen_string_literal: true

module Api
  module V1
    class PaymentsController < ApplicationController
      before_action :check_authorization, except: %i[create]
      before_action :check_policy_scope
      before_action :find_order
      before_action :find_payment, only: %i[show]

      def index
        @payments = @order.payments
      end

      def show; end

      def create
        authorize Payment
        return render_completed_error if @order.dispensed?

        @payment = Payments::Create.call(params, @order)
        render 'api/v1/orders/show', status: :created
      end

      private

      def find_order
        @order = current_user.orders.find(params[:order_id])
      end

      def find_payment
        @payment = Payment.find(params[:id])
      end

      def payment_params
        params.permit(:payment_method_id, :card_id, :token_id)
      end

      def render_completed_error
        render_error('Can\'t update/destroy a completed payment/order', :unprocessable_content)
      end

      def model_class
        Order
      end
    end
  end
end
