# frozen_string_literal: true

module Avo
  module Actions
    module UserFavorites
      class RemoveFromFavoritesAction < Avo::BaseAction
        self.name = 'Remove from Favorites'
        self.message = "Are you sure you want to remove this item from user's favorites?"
        self.confirm_button_label = 'Remove'
        self.cancel_button_label = 'Cancel'
        self.no_confirmation = false

        def fields
          # No additional fields needed for single removal
        end

        def handle(query:, **_args)
          removed_count = 0

          query.each do |user_favorite|
            removed_count += 1 if user_favorite.destroy
          end

          if removed_count.positive?
            succeed "#{removed_count} favorite(s) removed successfully"
          else
            error 'Failed to remove favorites'
          end
        rescue StandardError => e
          Rails.logger.error "Error removing favorites: #{e.message}"
          error 'An error occurred while removing favorites'
        end
      end
    end
  end
end
