# frozen_string_literal: true

module Avo
  module Resources
    class Location < Avo::BaseResource
      self.title = :name
      self.includes = %i[vending_machines]
      self.attachments = %i[images]
      self.record_selector = true
      self.default_view_type = :grid

      self.search = {
        results_count: 5,
        query: lambda {
                 query.ransack(
                   name_cont: params[:q],
                   landmark_start: params[:q],
                   city_cont: params[:q],
                   state_cont: params[:q],
                   m: 'or'
                 ).result(distinct: false)
               },
        help: -> { 'Search by landmark' }
      }

      def fields
        field :id, as: :id
        field :name, as: :text
        field :address, as: :text, hide_on: %i[index]
        field :city, as: :text, only_on: :index
        field :landmark, as: :text, hide_on: %i[index]
        field :state, as: :text
        field :zip_code, as: :text

        many_relation_tabs
      end

      def many_relation_tabs
        tabs id: :many_relations_tabs do
          field :vending_machines, as: :has_many, reloadable: true, linkable: true, searchable: true
        end
      end
    end
  end
end
