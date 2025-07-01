# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < ApplicationController
      before_action :set_category, only: %i[show]
      def index
        @categories = paginate(Category.all)
      end

      def show; end

      def with_brands
        @categories_with_brands = Category.with_brands
      end

      private

      def set_category
        @category = Category.find(params[:id])
      end
    end
  end
end
