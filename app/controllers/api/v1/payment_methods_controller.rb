# frozen_string_literal: true

module Api
  module V1
    class PaymentMethodsController < ApplicationController
      before_action :find_machine, only: :index
      before_action :find_payment_method, only: :show
      def index
        @payment_methods = paginate(PaymentMethod.active_for_machine)
      end

      def show; end

      private

      def find_payment_method
        @payment_method = PaymentMethod.find_by(id: params[:id])
      end

      def find_machine
        @machine = Machine.find_by(id: params[:machine_id])
      end
    end
  end
end
