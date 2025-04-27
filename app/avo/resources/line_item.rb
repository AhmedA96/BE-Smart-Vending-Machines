# frozen_string_literal: true

module Avo
  module Resources
    class LineItem < Avo::BaseResource
      self.includes = []
      self.attachments = []
      self.search = {
        query: -> { query.ransack(id_eq: params[:q], m: 'or').result(distinct: false) }
      }

      def fields
        field :id, as: :id
        field :quantity, as: :number, required: true
        field :price, as: :currency
        field :processed, as: :boolean
        field :price_after_discount, as: :currency
        field :buyx_gety_discount, as: :currency
        field :created_at, as: :date_time, sortable: true
        field :updated_at, as: :date_time, sortable: true
      end
    end
  end
end
