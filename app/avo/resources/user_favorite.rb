# frozen_string_literal: true

module Avo
  module Resources
    class UserFavorite < Avo::BaseResource
      self.title = :display_name
      self.includes = [:user, :variant, { variant: :product }]
      self.search = {
        query: lambda {
          query.joins(:user, variant: :product)
               .ransack(
                 user_email_cont: params[:q],
                 user_name_cont: params[:q],
                 variant_name_cont: params[:q],
                 variant_product_name_cont: params[:q],
                 m: 'or'
               ).result(distinct: false)
        }
      }
      def fields # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        field :id, as: :id, readonly: true

        field :user, as: :belongs_to,
                     searchable: true,
                     placeholder: 'Select a user',
                     display_with: -> { record.user&.email || 'No user' }

        field :variant, as: :belongs_to,
                        searchable: true,
                        placeholder: 'Select a variant',
                        display_with: lambda {
                          if record.variant
                            "#{record.variant.product&.name} - #{record.variant.name}"
                          else
                            'No variant'
                          end
                        }

        # field to show product info
        field :product_name, as: :text, readonly: true, hide_on: %i[new edit] do
          record.variant&.product&.name
        end

        # Show order count for this user-variant combination
        field :user_order_count, as: :number, readonly: true, hide_on: %i[new edit] do
          if record.user && record.variant
            record.variant.order_count_for_user(record.user)
          else
            0
          end
        end

        # Show last ordered date
        field :last_ordered, as: :date_time, readonly: true, hide_on: %i[new edit] do
          record.variant.last_ordered_by_user(record.user) if record.user && record.variant
        end

        field :created_at, as: :date_time, readonly: true,
                           sortable: true,
                           format: 'yyyy-MM-dd HH:mm',
                           show_on: :index

        field :updated_at, as: :date_time, readonly: true,
                           format: 'yyyy-MM-dd HH:mm',
                           hide_on: :index
      end

      def filters
        filter Avo::Filters::UserFavorites::DateFilter
        filter Avo::Filters::UserFavorites::UserFilter
        filter Avo::Filters::UserFavorites::ProductFilter
      end

      def actions
        action Avo::Actions::UserFavorites::RemoveFromFavoritesAction
      end

      def scopes
        scope :recent, 'Recent (Last 7 days)' do
          query.where(created_at: 7.days.ago..Time.current)
        end

        scope :this_month, 'This Month' do
          query.where(created_at: Date.current.all_month)
        end

        scope :popular_items, 'Popular Items' do
          # Favorites for items that have been ordered more than 10 times
          query.joins(variant: :line_items)
               .group('user_favorites.id')
               .having('COUNT(line_items.id) > 10')
        end
      end
    end
  end
end
