# frozen_string_literal: true

module Avo
  module Resources
    class Location < Avo::BaseResource
      include ResourceHelpers
      self.title = :name
      self.includes = %i[machines translations]
      self.attachments = []
      self.record_selector = true

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
        field :address, as: :text
        field :city, as: :text, hide_on: :index
        field :landmark, as: :text, hide_on: %i[index]
        field :state, as: :text, hide_on: :index
        field :zip_code, as: :text, hide_on: :index
        field :coordinates, as: :text, hide_on: %i[index],
                            help: 'Enter coordinates in format: POINT (40.7128 74.0060)'
        field :price_list, as: :belongs_to
        field :country, as: :belongs_to

        many_relation_tabs
      end

      def many_relation_tabs
        tabs id: :many_relations_tabs do
          field :machines, as: :has_many, reloadable: true, linkable: true, searchable: true
          field :location_translations, as: :has_many, reloadable: true, linkable: true, searchable: true
        end
      end
    end
  end
end
