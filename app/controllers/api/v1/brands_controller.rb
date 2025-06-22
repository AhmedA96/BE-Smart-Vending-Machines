# frozen_string_literal: true

module Api
  module V1
    class BrandsController < ApplicationController
      def index
        @brands = paginate(Brand.all)
      end
    end
  end
end
