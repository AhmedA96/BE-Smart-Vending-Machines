# frozen_string_literal: true

module Avo
  module Resources
    class VendingMachine < Avo::BaseResource
      include ResourceHelpers
      self.title = :name
      self.includes = %i[machine_statuses machine_products]
      self.record_selector = true
      self.attachments = []

      self.search = {
        results_count: 5,
        query: lambda {
          query.ransack(
            id_eq: params[:q],
            name_cont: params[:q],
            m: 'or'
          ).result(distinct: false)
        },
        item: lambda {
                {
                  title: record&.name&.to_s,
                  description: record&.status
                }
              },
        help: -> { 'Search by Machine name' }
      }

      def self.name
        'Machines'
      end

      def fields
        status = %w[Active Inactive Maintenance Retired]
        field :id, as: :id
        field :name, as: :text
        field :vendor, as: :belongs_to
        field :location_name, as: :text
        field :status, as: :select, enum: status, hide_on: %i[show], summarizable: true
        field :status, as: :badge, enum: status, only_on: %i[index show],
                       options: { danger: %i[Inactive], success: %i[Active],
                                  warning: %i[Maintenance], neutral: %i[Retired] }
        field :category, as: :belongs_to, hide_on: %i[index]
        field :manufacturer_id, as: :text, hide_on: %i[index]
        field :installed_at, as: :date_time, hide_on: %i[index]
        field :last_service_date, as: :date_time, hide_on: %i[index]

        many_relations
      end

      def many_relations
        tabs id: :many_relation_tabs do
          field :machine_products, as: :has_many, reloadable: true, name: 'Machine Products'
        end
      end
    end
  end
end
