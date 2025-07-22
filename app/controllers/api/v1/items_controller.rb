# frozen_string_literal: true

module Api
  module V1
    class ItemsController < ApplicationController
      def popular
        @items = Rails.cache.fetch("popular_items_#{params[:limit] || 10}", expires_in: 1.hour) do
          Variant.includes(:product).popular(params[:limit] || 10)
        end
      end

      def trending
        @days = params[:days]&.to_i || 7
        @items = Rails.cache.fetch("trending_items_#{@days}_days_#{params[:limit] || 10}", expires_in: 30.minutes) do
          Variant.includes(:product).trending(@days, params[:limit] || 10)
        end
      end
    end
  end
end
