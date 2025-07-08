# frozen_string_literal: true

module Avo
  module Resources
    class Supplier < Avo::BaseResource
      include ResourceHelpers

      self.title = :name
      self.includes = %i[machines image_attachment]
      self.attachments = []
      self.record_selector = false
      self.search = {
        query: lambda {
          query.ransack(
            name_cont: params[:q],
            app_id_cont: params[:q],
            base_url_cont: params[:q],
            m: 'or'
          ).result(distinct: true)
        },
        item: lambda {
          {
            title: record&.name,
            description: "App ID: #{record&.app_id} - #{record&.base_url}"
          }
        },
        help: -> { 'Search by supplier name, app ID, or base URL' }
      }

      def fields
        field :id, as: :id
        field :name, as: :text, required: true
        field :app_id, as: :text, required: true
        field :app_secret, as: :password, required: true, show_on: :edit
        field :base_url, as: :text, placeholder: 'https://example.com/api'
        field :image, as: :file, is_image: true, accept: 'image/*', direct_upload: true
        field :created_at, as: :date_time, hide_on: :forms
        field :updated_at, as: :date_time, hide_on: :forms

        tabs id: :many_relations_tabs do
          many_relations_tabs
        end
      end

      def many_relations_tabs
        field :machines, as: :has_many
      end
    end
  end
end
