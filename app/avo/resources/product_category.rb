# frozen_string_literal: true

module Avo
  module Resources
    class ProductCategory < Avo::BaseResource
      # self.includes = []
      # self.attachments = []
      # self.search = {
      #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
      # }

      def fields
        field :id, as: :id
        field :product, as: :belongs_to
        field :category, as: :belongs_to
        field :name, as: :text, only_on: :index, hide_on: :forms
        field :created_at, as: :date_time
        field :updated_at, as: :date_time
      end
    end
  end
end
