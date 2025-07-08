# frozen_string_literal: true

module Api
  module V1
    class MachinesController < ApplicationController
      before_action :set_machine, only: %i[show]
      before_action :set_location, only: %i[by_location]

      def nearby
        @machines = paginate(
          Machine.nearby(
            latitude: params[:latitude],
            longitude: params[:longitude]
          ).includes(:category).includes(:location)
        )
        render :index
      end

      def by_location
        @machines = paginate(
          @location.machines.active.includes(:category).includes(:location)
        )
        render :index
      end

      def show; end

      private

      def set_machine
        @machine = Machine.find(params[:id])
      end

      def set_location
        @location = Location.find(params[:location_id])
      end
    end
  end
end
