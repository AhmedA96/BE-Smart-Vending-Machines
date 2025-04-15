# frozen_string_literal: true

module Avo
  module Resources
    class MachineStatus < Avo::BaseResource
      include ResourceHelpers
      self.title = :status
      self.includes = [:vending_machine]
      self.search = {
        query: -> { query.ransack(id_eq: params[:q], status_cont: params[:q], m: 'or').result(distinct: false) }
      }

      def fields
        status = %w[Active Inactive Maintenance Retired]
        field :id, as: :id
        field :vending_machine, as: :belongs_to, searchable: true
        field :status, as: :select, enum: status, hide_on: %i[show], summarizable: true
        field :changed_at, as: :date_time, required: true
        field :notes, as: :textarea
        field :created_at, as: :date_time, readonly: true, hide_on: %i[index]
        field :updated_at, as: :date_time, readonly: true, hide_on: %i[index]
      end
    end
  end
end
