# frozen_string_literal: true

module Api
  module V1
    class VariantsController < ApplicationController
      before_action :find_product, only: [:index]
      before_action :find_variant, only: [:show]

      def index
        @variants = paginate(@product.variants)
      end

      def show; end

      private

      def find_product
        @product = Product.find(params[:product_id])
      end

      def find_variant
        @variant = Variant.find(params[:id])
      end
    end
  end
end
