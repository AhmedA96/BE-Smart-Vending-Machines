# frozen_string_literal: true

module Avo
  module Resources
    class Product < Avo::BaseResource
      self.title = :name
      self.includes = %i[product_categories images_attachments]
      self.attachments = %i[images]
      self.record_selector = true
      self.default_view_type = :grid

      self.search = {
        results_count: 5,
        query: lambda {
                 query.ransack(
                   name_cont: params[:q],
                   name_start: params[:q],
                   slug_cont: params[:q],
                   category_name_cont: params[:q],
                   m: 'or'
                 ).result(distinct: false)
               },
        item: lambda {
                {
                  title: record&.name&.to_s,
                  description: record&.status,
                  image_url: (main_app.url_for(record.images.first) if record.images.attached?),
                  image_format: :rounded
                }
              },
        help: -> { 'Search by product' }
      }

      self.grid_view = {
        card: lambda {
                {
                  cover_url: (main_app.url_for(record.images.first) if record.images.attached?),
                  title: record.name,
                  body: ActionView::Base.full_sanitizer.sanitize(record&.description)&.to_s&.truncate(100),
                  badge_label: (record.status == 'Active' ? I18n.t('active') : I18n.t('inactive')),
                  badge_color: (record.status == 'Active' ? 'green' : 'red')
                }
              }
      }

      def fields
        status = %w[Active Inactive]
        field :id, as: :id
        field :name, as: :text
        field :presentation, as: :text, hide_on: %i[index]
        field :sku_sales, as: :text, only_on: :index do
          record&.variants&.joins(:line_items)&.group('variants.sku')
                &.sum('line_items.quantity * line_items.price')
                &.values&.join(', ')
        end
        field :description, as: :text, hide_on: %i[index]
        field :images, as: :files, is_image: true, accept: 'image/*', direct_upload: true
        field :status, as: :select, enum: status, hide_on: %i[show], summarizable: true
        field :status, as: :badge, enum: status, only_on: %i[index show],
                       options: { danger: %i[Inactive], success: %i[Active] }
        field :slug, as: :text
        field :total_rate, as: :number, hide_on: %i[index show]
        field :max_orderable_quantity, as: :number, hide_on: %i[index]
        field :sorting, as: :number, hide_on: %i[index]
        field :start_date, as: :date
        field :end_date, as: :date

        many_relation_tabs
      end

      def many_relation_tabs
        tabs id: :many_relations_tabs do
          field :variants, as: :has_many, reloadable: true, linkable: true, searchable: true
        end
      end
    end
  end
end
