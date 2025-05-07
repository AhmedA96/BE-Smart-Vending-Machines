# frozen_string_literal: true

module Api
  module V1
    class MachineCategoriesController < ApplicationController
      before_action :set_category, only: %i[show]
      def index
        @machine_categories = paginate(MachineCategory.all)
      end

      def show; end

      private

      def set_category
        @machine_category = MachineCategory.find(params[:id])
      end
    end
  end
end
