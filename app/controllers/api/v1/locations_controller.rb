# frozen_string_literal: true

module Api
  module V1
    class LocationsController < ApplicationController
      before_action :set_location, only: %i[show]

      def nearby
        @locations = paginate(
          Location.nearby(
            latitude: params[:latitude],
            longitude: params[:longitude],
            radius_km: params[:radius]
          ).includes(:translations)
        )
      end

      def show; end

      private

      def set_location
        @location = Location.find(params[:id])
      end
    end
  end
end
