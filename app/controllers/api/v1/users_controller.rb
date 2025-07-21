# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      before_action :current_user

      def most_ordered_items
        @items = paginate(@current_user.most_ordered_variants(limit: params[:limit] || 10))
      end
    end
  end
end
