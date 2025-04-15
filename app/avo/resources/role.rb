# frozen_string_literal: true

module Avo
  module Resources
    class Role < Avo::BaseResource
      include ResourceHelpers

      self.title = :role_title
      self.includes = [:resource]
      self.visible_on_sidebar = false
      self.search = {
        query: lambda {
          query.ransack(name_cont: params[:q], m: 'or').result(distinct: false)
        },
        help: -> { 'Search by role name' }
      }

      def fields
        roles = ROLES
        field :id, as: :id
        field :name, as: :text, only_on: :display do
          record&.name&.humanize
        end
        field :name, as: :select, enum: roles, only_on: :forms
      end
    end
  end
end
