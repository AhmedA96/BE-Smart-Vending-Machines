# frozen_string_literal: true

module Api
  module V1
    class MachinesController < ApplicationController
      before_action :set_machine, only: %i[show]

      def nearby
        @machines = paginate(
          Machine.nearby(
            latitude: params[:latitude],
            longitude: params[:longitude]
          ).includes(:category).includes(:location)
        )
      end

      def show; end

      private

      def set_machine
        @machine = Machine.find(params[:id])
      end
    end
  end
end
