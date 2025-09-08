# frozen_string_literal: true

module Api
  module V1
    class MachineCategoriesController < ApplicationController
      before_action :set_category, only: %i[show]
      def index
        categories = MachineCategory.for_nearby_machines(
          latitude: params[:latitude],
          longitude: params[:longitude]
        ).includes(:translations, :logo_attachment)

        @machine_categories = paginate(categories)
      end

      def show; end

      private

      def set_category
        @machine_category = MachineCategory.find(params[:id])
      end
    end
  end
end
