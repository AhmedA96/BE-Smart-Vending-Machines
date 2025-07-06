# frozen_string_literal: true

module Api
  module V1
    class PaymentMethodsController < ApplicationController
      before_action :find_payment_method, only: :show
      def index
        @payment_methods = paginate(PaymentMethod.all)
      end

      def show; end

      private

      def find_payment_method
        @payment_method = PaymentMethod.find(params[:id])
      end
    end
  end
end
