# frozen_string_literal: true

module Api
  module V1
    class UserFavoritesController < ApplicationController
      before_action :current_user

      def create
        @favorite = @current_user.user_favorites.build(product_id: params[:product_id])

        if @favorite.save
          render json: {
            message: 'Item added to favorites',
            favorite: {
              product_id: @favorite.product_id,
              product_name: @favorite.product.name,
              favorited_at: @favorite.created_at
            }
          }, status: :created
        else
          render json: {
            errors: @favorite.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        @favorite = @current_user.user_favorites.find_by(product_id: params[:product_id])

        if @favorite
          @favorite.destroy
          render json: { message: 'Item removed from favorites' }
        else
          render json: { error: 'Favorite not found' }, status: :not_found
        end
      end
    end
  end
end
