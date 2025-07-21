# frozen_string_literal: true

module Avo
  module Resources
    class MachineType < Avo::BaseResource
      include ResourceHelpers
      self.title = :name
      self.includes = %i[machines]

      self.search = {
        query: -> { query.ransack(name_cont: params[:q], m: 'or').result(distinct: false) },
        item: lambda {
                {
                  title: record&.name&.to_s
                }
              },
        help: -> { 'Search by type' }
      }

      def fields
        field :id, as: :id
        field :name, as: :text, required: true
        field :capacity, as: :text
        field :has_temperature_control, as: :boolean, required: true, hide_on: %i[index]
        field :created_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
        field :updated_at, as: :date_time, readonly: true, hide_on: %i[index edit new]

        many_relation_tabs
      end

      def many_relation_tabs
        tabs id: :many_relations do
          field :machines, as: :has_many, reloadable: true, linkable: true
        end
      end
    end
  end
end
