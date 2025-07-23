# frozen_string_literal: true

module Avo
  module Filters
    module UserFavorites
      class UserFilter < Avo::Filters::SelectFilter
        self.name = 'User'

        def apply(_request, query, value)
          return query if value.blank?

          query.where(user_id: value.to_i)
        end

        def options
          users_data = User.joins(:user_favorites)
                           .distinct
                           .order(:name)
                           .limit(100)
                           .pluck(:id, :name)

          users_data.to_h { |id, name| [id, name] }
        rescue StandardError => e
          Rails.logger.error "UserFilter error: #{e.message}"
          { nil => 'Error loading users' }
        end
      end
    end
  end
end
