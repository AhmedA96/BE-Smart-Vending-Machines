# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :current_user
      before_action :set_notification, only: %i[mark_as_read destroy]

      def index
        @notifications = paginate(current_user.notifications.recent).includes(:notifiable)
      end

      def mark_as_read
        @notification.mark_as_read!
        render :show
      end

      def mark_all_as_read
        current_user.notifications.unread.find_each do |notification|
          notification.update(read: true, read_at: Time.current)
        end

        render json: { message: I18n.t('notifications.mark_all_as_read') }, status: :ok
      end

      def destroy
        @notification.destroy

        head :no_content
      end

      private

      def set_notification
        @notification = current_user.notifications.find(params[:id])
      end
    end
  end
end
