# frozen_string_literal: true

module Avo
  module Filters
    module UserFavorites
      class ProductFilter < Avo::Filters::SelectFilter
        self.name = 'Product'

        def apply(_request, query, value)
          return query if value.blank?

          Rails.logger.info "ProductFilter applying with product ID: #{value}"
          Rails.logger.info "Query before filter: #{query.count} records"

          # Filter UserFavorites by product
          filtered_query = query.joins(variant: :product).where(products: { id: value.to_i })

          Rails.logger.info "Query after filter: #{filtered_query.count} records"
          filtered_query
        end

        def options
          products_with_favorites = Product.joins(variants: :user_favorites)
                                           .where(deleted_at: nil)
                                           .distinct
                                           .select('products.*, COUNT(user_favorites.id) as favorites_count')
                                           .group('products.id')
                                           .order(:name)

          options_hash = {}
          products_with_favorites.each do |product|
            options_hash[product.id] = "#{product.name} (#{product.favorites_count} favorites)"
          end

          Rails.logger.info "Product filter options: #{options_hash}"
          options_hash
        rescue StandardError => e
          Rails.logger.error "ProductFilter error: #{e.message}"
          { nil => 'Error loading products' }
        end
      end
    end
  end
end
