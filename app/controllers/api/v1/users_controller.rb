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

      def profile; end

      def update_profile
        if @current_user.update(profile_params)
          render :profile
        else
          render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @current_user.destroy
          render json: { message: I18n.t('user.account_deleted') }, status: :ok
        else
          render json: {
            errors: @current_user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def profile_params
        params.expect(user: %i[name avatar email date_of_birth locale])
      end
    end
  end
end
