# frozen_string_literal: true

module Avo
  module Resources
    class Machine < Avo::BaseResource
      include ResourceHelpers

      self.title = :name
      self.includes = %i[]
      self.record_selector = true
      self.attachments = %i[image]
      self.default_view_type = :grid

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

      self.grid_view = {
        card: lambda {
          {
            cover_url: (main_app.url_for(record.image) if record.image.attached?),
            title: record.name,
            body: ActionView::Base.full_sanitizer.sanitize(record&.name)&.to_s&.truncate(100),
            badge_label: "#{record.status} • #{record.stocked? ? 'Stocked' : 'Empty'}",
            badge_color: if record.status == 'Active' && record.stocked?
                           'green'
                         elsif record.status == 'Active' && !record.stocked?
                           'yellow'
                         else
                           'red'
                         end
          }
        }
      }

      def fields
        status = %w[Active Inactive Maintenance Retired]
        field :id, as: :id
        field :name, as: :text
        field :machineuuid, as: :text
        field :vendor, as: :belongs_to
        field :supplier, as: :belongs_to
        field :location, as: :belongs_to
        field :image, as: :file, is_image: true, accept: 'image/*', direct_upload: true, hide_on: %i[index]
        field :status, as: :select, enum: status, hide_on: %i[show], summarizable: true
        field :status, as: :badge, enum: status, only_on: %i[index show],
                       options: { danger: %i[Inactive], success: %i[Active],
                                  warning: %i[Maintenance], neutral: %i[Retired] }
        field :category, as: :belongs_to, hide_on: %i[index]
        field :machineuuid, as: :text, hide_on: %i[index]
        field :stock_indicator,
              as: :text,
              name: 'Stock',
              sortable: false,
              format_using: lambda {
                if record.stocked?
                  view_context.raw('<span style="color: #22c55e; font-weight: bold;">● Stocked</span>')
                else
                  view_context.raw('<span style="color: #ef4444; font-weight: bold;">● Empty</span>')
                end
              },
              read_only: true

        field :coordinates, as: :text, hide_on: %i[index edit new]
        field :installed_at, as: :date_time, hide_on: %i[index]
        field :last_service_date, as: :date_time, hide_on: %i[index]
        field :machine_type, as: :belongs_to, hide_on: %i[index]

        many_relations
      end

      def many_relations
        tabs id: :many_relation_tabs do
          field :machine_items, as: :has_many, reloadable: true, name: 'Machine Items'
          field :machine_translations, as: :has_many, reloadable: true, name: 'Machine Translations'
          field :machine_payment_methods, as: :has_many, reloadable: true, name: 'Payment Methods', linkable: true
          field :machine_statuses, as: :has_many, reloadable: true, name: 'Status History', linkable: true
          field :orders, as: :has_many, reloadable: true, name: 'Orders', linkable: true
        end
      end
    end
  end
end
