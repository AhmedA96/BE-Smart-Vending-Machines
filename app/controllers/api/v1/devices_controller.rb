# frozen_string_literal: true

module Api
  module V1
    class DevicesController < ApplicationController
      before_action :current_user

      def create
        device = current_user.devices.find_or_initialize_by(token: device_params[:token])
        device.platform = device_params[:platform]
        device.last_used_at = Time.current
        device.save!

        render json: { message: 'Device registered successfully' }, status: :ok
      end

      def destroy
        current_user.devices.find_by(token: params[:token])&.destroy
        head :no_content
      end

      private

      def device_params
        params.expect(device: %i[token platform])
      end
    end
  end
end
