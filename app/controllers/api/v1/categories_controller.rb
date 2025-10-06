# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < ApplicationController
      before_action :set_machine, only: %i[index]
      before_action :set_category, only: %i[show]
      def index
        @categories = paginate(Category.for_machine(@machine).includes(:translations, :logo_attachment))
      end

      def show; end

      def with_brands
        @categories_with_brands = Category.with_brands
      end

      private

      def set_category
        @category = Category.find(params[:id])
      end

      def set_machine
        @machine = Machine.find(params[:machine_id])
      end
    end
  end
end
