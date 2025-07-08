# frozen_string_literal: true

module Api
  module V1
    class BrandsController < ApplicationController
      before_action :set_location, only: %i[index]

      def index
        @brands = paginate(Brand.by_location(params[:location_id]))
      end

      private

      def set_location
        @location = Location.find(params[:location_id])
      end
    end
  end
end
