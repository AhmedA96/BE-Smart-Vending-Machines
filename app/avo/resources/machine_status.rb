# frozen_string_literal: true

module Avo
  module Resources
    class MachineStatus < Avo::BaseResource
      # self.includes = []
      # self.attachments = []
      # self.search = {
      #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
      # }

      def fields
        field :id, as: :id
        field :vending_machine, as: :belongs_to
        field :status, as: :select, options: {
          active: 'active',
          maintenance: 'maintenance',
          inactive: 'inactive',
          retired: 'retired'
        }
        field :changed_at, as: :date_time
        field :notes, as: :textarea
      end
    end
  end
end
