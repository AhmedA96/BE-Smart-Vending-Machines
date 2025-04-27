# frozen_string_literal: true

module Avo
  module Resources
    class MachineCategory < Avo::BaseResource
      include ResourceHelpers
      self.title = :name
      self.includes = [:machines]
      self.search = {
        query: -> { query.ransack(id_eq: params[:q], name_cont: params[:q], m: 'or').result(distinct: false) }
      }

      def fields
        field :id, as: :id
        field :name, as: :text, required: true
        field :description, as: :textarea
        field :created_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
        field :updated_at, as: :date_time, readonly: true, hide_on: %i[index edit new]

        many_relation_tabs
      end

      def many_relation_tabs
        tabs id: :many_relations_tabs do
          field :machines, as: :has_many, reloadable: true, linkable: true, searchable: true
        end
      end
    end
  end
end
