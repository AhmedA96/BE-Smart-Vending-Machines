# frozen_string_literal: true

module Api
  module V1
    class VendingMachinesController < ApplicationController
      def nearby
        @vending_machines = VendingMachine.nearby(
          latitude: params[:latitude],
          longitude: params[:longitude]
        )
      end
    end
  end
end
