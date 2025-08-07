# frozen_string_literal: true

module Avo
  module Resources
    class Vendor < Avo::BaseResource
      include ResourceHelpers

      self.title = :name
      self.includes = %i[machines]
      self.record_selector = true
      self.attachments = []

      self.search = {
        results_count: 5,
        query: lambda {
          query.ransack(
            id_eq: params[:q],
            name_cont: params[:q],
            email_cont: params[:q],
            contact_person_cont: params[:q],
            m: 'or'
          ).result(distinct: false)
        },
        item: lambda {
          {
            title: record&.name&.to_s,
            description: record&.email
          }
        },
        help: -> { 'Search by Vendor name or Contact person' }
      }

      def fields
        field :id, as: :id
        field :name, as: :text
        field :email, as: :text
        field :contact_person, as: :text
        field :phone_number, as: :text, hide_on: %i[index]
        field :address, as: :textarea, hide_on: %i[index]

        many_relations
      end

      def many_relations
        tabs id: :many_relation_tabs do
          field :machines, as: :has_many, reloadable: true
        end
      end
    end
  end
end
