# frozen_string_literal: true

module Api
  module V1
    class MachinesController < ApplicationController
      before_action :set_machine, only: %i[show]
      before_action :set_machine_type, only: %i[index nearby]

      def index
        @machines = paginate(Machines::Filter.call(params)).includes(:translations, :location, :category,
                                                                     :image_attachment, :machine_type,
                                                                     supplier: :image_attachment)
      end

      def nearby
        machines_query = Machine.nearby(
          latitude: params[:latitude],
          longitude: params[:longitude]
        )

        # Filter by machine type if provided
        machines_query = machines_query.where(machine_type: @machine_type) if params[:machine_type_id].present?

        @machines = paginate(machines_query.includes(:category, :location, :machine_type))
        render :index
      end

      def show; end

      private

      def set_machine
        @machine = Machine.find(params[:id])
      end

      def set_machine_type
        @machine_type = MachineType.find_by(id: params[:machine_type_id]) if params[:machine_type_id].present?
      end
    end
  end
end
