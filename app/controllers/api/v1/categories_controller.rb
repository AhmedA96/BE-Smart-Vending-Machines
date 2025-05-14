# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < ApplicationController
      skip_before_action :doorkeeper_authorize!
      before_action :set_category, only: %i[show]
      def index
        @categories = paginate(Category.all)
      end

      def show; end

      private

      def set_category
        @category = Category.find(params[:id])
      end
    end
  end
end
