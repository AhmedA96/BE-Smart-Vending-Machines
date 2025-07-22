# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      before_action :current_user

      def most_ordered_items
        @items = @current_user.most_ordered_variants(limit: params[:limit] || 10)
      end

      def favorite_items
        @favorites = @current_user.user_favorites.includes(variant: :product)
                                  .recent
                                  .limit(params[:limit] || 20)
      end
    end
  end
end
