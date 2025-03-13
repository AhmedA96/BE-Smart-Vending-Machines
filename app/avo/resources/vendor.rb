# frozen_string_literal: true

module Avo
  module Resources
    class Vendor < Avo::BaseResource
      # self.includes = []
      # self.attachments = []
      # self.search = {
      #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
      # }

      def fields
        field :id, as: :id
        field :name, as: :text
        field :contact_person, as: :text
        field :phone_number, as: :text
        field :email, as: :text
        field :address, as: :textarea
      end
    end
  end
end
