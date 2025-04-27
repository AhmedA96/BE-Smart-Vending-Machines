# frozen_string_literal: true

module Api
  module V1
    class MachinesController < ApplicationController
      include Paginable

      def nearby
        @machines = paginate(
          Machine.nearby(
            latitude: params[:latitude],
            longitude: params[:longitude]
          )
        )
      end
    end
  end
end
