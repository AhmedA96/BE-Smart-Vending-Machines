# frozen_string_literal: true

module Avo
  module Resources
    class MachineStatus < Avo::BaseResource
      include ResourceHelpers
      self.title = :status
      self.visible_on_sidebar = false
      self.includes = []
      self.search = {
        query: -> { query.ransack(id_eq: params[:q], status_cont: params[:q], m: 'or').result(distinct: false) }
      }

      def fields
        status = %w[Active Inactive Maintenance Retired]
        field :id, as: :id
        field :machine, as: :belongs_to, searchable: true
        field :status, as: :select, enum: status, hide_on: %i[show], summarizable: true
        field :changed_at, as: :date_time, required: true
        field :notes, as: :textarea
        field :created_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
        field :updated_at, as: :date_time, readonly: true, hide_on: %i[index edit new]
      end
    end
  end
end
