# frozen_string_literal: true

module Avo
  module Resources
    class Address < Avo::BaseResource
      include ResourceHelpers

      self.title = :address
      self.includes = %i[country]
      self.record_selector = false
      self.visible_on_sidebar = true
      self.search = {
        query: lambda {
          query.ransack(address_cont: params[:q], name_cont: params[:q], m: 'or').result(distinct: true)
        },
        item: lambda {
          {
            title: "#{record&.name} - #{record.address}",
            description: "#{record.addressable_type}: #{record.addressable.name}"
          }
        },
        help: -> { 'Search by address' }
      }

      def fields
        main_panel do
          field :id, as: :id
          field :name, as: :text
          field :city, as: :text
          field :address, as: :text
          field :default, as: :boolean

          sidebar do
            field :building_number, as: :text
            field :floor_number, as: :text
            field :appart_number, as: :text
          end
        end
      end
    end
  end
end
