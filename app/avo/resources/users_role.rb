# frozen_string_literal: true

module Avo
  module Resources
    class UsersRole < Avo::BaseResource
      include ResourceHelpers

      self.title = :name
      self.includes = %i[user role]
      self.visible_on_sidebar = lambda {
        current_user.admin?
      }
      self.id = :id
      self.model_class = ::UsersRole

      def fields
        field :id, as: :id
        limited_field :user, as: :belongs_to, searchable: true
        limited_field :role, as: :belongs_to, searchable: true
      end
    end
  end
end
