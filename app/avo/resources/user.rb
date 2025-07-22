# frozen_string_literal: true

module Avo
  module Resources
    class User < Avo::BaseResource
      include ResourceHelpers
      include Pundit::Authorization

      self.title = :resource_title
      self.record_selector = true
      self.devise_password_optional = true
      self.profile_photo = {
        size: :lg,
        visible_on: %i[show],
        source: -> { record&.avatar }
      }
      self.search = {
        results_count: -> { current_user.admin? ? 20 : 5 },
        query: lambda {
          query
            .includes(:roles)
            .ransack(id_eq: params[:q], name_cont: params[:q],
                     mobile_number_cont: params[:q], email_cont: params[:q], m: 'or')
            .result(distinct: true)
        },
        item: lambda {
          {
            title: "#{record.name} (#{record.email})",
            description: record.mobile_number.to_s
          }
        },
        help: -> { '- Search by name or mobile number or email' }
      }

      def fields
        field :id, as: :id
        image_fields
        field :name, as: :text, filterable: true
        field :email, as: :text, hide_on: %i[index]
        field :mobile_number, as: :text, filterable: true
        field :date_of_birth, as: :date, only_on: (admin? ? nil : :display),
                              filterable: true, hide_on: %i[index]
        field :created_at, as: :date_time, filterable: true, hide_on: %i[new edit]
        field :password, as: :password, visible: admin?, revealable: true
        field :wallet, as: :has_one, only_on: %i[show edit], searchable: true

        many_relations
      end

      def many_relations
        tabs id: :many_relation_tabs do
          field :users_roles, as: :has_many, reloadable: true, name: 'Roles'
          field :user_favorites, as: :has_many, reloadable: true, name: 'Favorites'
          field :orders, as: :has_many, reloadable: true, name: 'Orders'
        end
      end

      def image_fields
        field :avatar, as: :external_image, radius: 30, only_on: :index do
          record&.avatar
        rescue StandardError
          nil
        end
      end
    end
  end
end
