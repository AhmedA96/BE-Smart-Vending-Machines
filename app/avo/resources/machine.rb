# frozen_string_literal: true

module Avo
  module Resources
    class Machine < Avo::BaseResource
      include ResourceHelpers
      self.title = :name
      self.includes = %i[machine_statuses machine_items translations machine_payment_methods]
      self.record_selector = true
      self.attachments = %i[image]

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

      def fields
        status = %w[Active Inactive Maintenance Retired]
        field :id, as: :id
        field :name, as: :text
        field :vendor, as: :belongs_to
        field :supplier, as: :belongs_to
        field :location, as: :belongs_to
        field :image, as: :file, is_image: true, accept: 'image/*', direct_upload: true, hide_on: %i[index]
        field :status, as: :select, enum: status, hide_on: %i[show], summarizable: true
        field :status, as: :badge, enum: status, only_on: %i[index show],
                       options: { danger: %i[Inactive], success: %i[Active],
                                  warning: %i[Maintenance], neutral: %i[Retired] }
        field :category, as: :belongs_to, hide_on: %i[index]
        field :external_machine_id, as: :text, hide_on: %i[index]
        field :coordinates, as: :text, hide_on: %i[index],
                            help: 'Enter coordinates in format: POINT (40.7128 74.0060)'
        field :installed_at, as: :date_time, hide_on: %i[index]
        field :last_service_date, as: :date_time, hide_on: %i[index]

        many_relations
      end

      def many_relations
        tabs id: :many_relation_tabs do
          field :machine_items, as: :has_many, reloadable: true, name: 'Machine Items'
          field :machine_translations, as: :has_many, reloadable: true, name: 'Machine Translations'
          field :machine_payment_methods, as: :has_many, reloadable: true, name: 'Payment Methods', linkable: true
          field :machine_statuses, as: :has_many, reloadable: true, name: 'Status History', linkable: true
        end
      end
    end
  end
end
