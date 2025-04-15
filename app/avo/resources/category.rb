# frozen_string_literal: true

module Avo
  module Resources
    class Category < Avo::BaseResource
      # self.includes = []
      # self.attachments = []
      # self.search = {
      #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
      # }

      def fields
        field :id, as: :id
        field :name, as: :text, required: true
        field :presentation, as: :text, required: true
        field :position, as: :number, default: 0
        field :active, as: :boolean, default: true
        field :parent_category, as: :belongs_to, searchable: true
        field :created_at, as: :date_time, readonly: true
        field :updated_at, as: :date_time, readonly: true
      end
    end
  end
end
