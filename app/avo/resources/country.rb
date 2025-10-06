# frozen_string_literal: true

module Avo
  module Resources
    class Country < Avo::BaseResource
      include ResourceHelpers

      self.title = :name
      self.includes = %i[machines translations]
      self.attachments = []
      self.record_selector = false
      self.search = {
        query: lambda {
          query.ransack(
            name_cont: params[:q],
            presentation_cont: params[:q],
            currency_cont: params[:q],
            m: 'or'
          ).result(distinct: true)
        },
        item: lambda {
          {
            title: record&.name,
            description: "#{record.iso2} - #{record&.currency} (#{record.time_zone})"
          }
        },
        help: -> { 'Search by country name or currency' }
      }

      def fields
        field :id, as: :id
        field :name, as: :select, enum: ::Country.names, required: true, only_on: :forms
        field :presentation, as: :text
        field :iso2, as: :text, required: true
        field :vat_percentage, as: :number, step: 0.1, min: 0, max: 100, required: true
        field :currency, as: :select, enum: ::Country.currencies, required: true
        field :country_code, as: :text, required: true

        field :time_zone, as: :select, options: time_zone_options

        field :image, as: :file, is_image: true, accept: 'image/*', direct_upload: true

        tabs id: :many_relations_tabs do
          many_relations_tabs
        end
      end

      def many_relations_tabs
        field :locations, as: :has_many
        field :country_translations, as: :has_many
        field :addresses, as: :has_many
      end

      private

      def time_zone_options
        ActiveSupport::TimeZone.all.map do |tz|
          offset = tz.utc_offset / 3600.0
          formatted_offset = format('%+03d:00', offset)
          ["(#{tz.tzinfo.name}) #{tz.name} #{formatted_offset}", tz.name]
        end
      end
    end
  end
end
