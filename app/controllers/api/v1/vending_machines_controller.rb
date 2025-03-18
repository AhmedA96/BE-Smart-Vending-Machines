# frozen_string_literal: true

module Api
  module V1
    class VendingMachinesController < ApplicationController
      def nearby
        @vending_machines = VendingMachine.nearby(
          latitude: params[:latitude],
          longitude: params[:longitude]
        )

        if @vending_machines.empty?
          render json: { message: 'No machines nearby', machines: [] }, status: :ok
        else
          render json: {
            message: 'Machines found',
            machines: @vending_machines.map(&:as_nearby_json)
          }, status: :ok
        end
      end
    end
  end
end
