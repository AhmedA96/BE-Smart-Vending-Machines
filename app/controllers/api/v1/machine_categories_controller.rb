# frozen_string_literal: true

module Api
  module V1
    class MachineCategoriesController < ApplicationController
      before_action :set_category, only: %i[show]
      before_action :set_location, only: %i[index]
      def index
        @machine_categories = paginate(MachineCategory.by_location(params[:location_id]))
      end

      def show; end

      private

      def set_category
        @machine_category = MachineCategory.find(params[:id])
      end

      def set_location
        @location = Location.find(params[:location_id])
      end
    end
  end
end
