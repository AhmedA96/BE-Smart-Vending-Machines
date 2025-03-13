# frozen_string_literal: true

module Avo
  module Resources
    class VendingMachine < Avo::BaseResource
      # self.includes = []
      # self.attachments = []
      # self.search = {
      #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
      # }

      def fields
        field :id, as: :id
        field :manufacturer_id, as: :text
        field :name, as: :text
        field :category, as: :belongs_to
        field :vendor, as: :belongs_to
        field :location_name, as: :text
        field :latitude, as: :number
        field :longitude, as: :number
        field :status, as: :text
        field :installed_at, as: :date_time
        field :last_service_date, as: :date_time
      end
    end
  end
end
