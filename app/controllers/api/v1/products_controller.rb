# frozen_string_literal: true

module Api
  module V1
    class ProductsController < ApplicationController
      before_action :set_product, only: %i[show]
      def index
        @products = paginate(Products::FilterService.new(params).call.includes(:variants))
      end

      def show; end

      private

      def set_product
        @product = Product.find(params[:id])
      end
    end
  end
end
