# frozen_string_literal: true

module RansackScope
  extend ActiveSupport::Concern

  included do
    scope :ransack_filter, lambda { |params|
      q = ransack(params[:q] || {})

      q.sorts = params[:sorts] if params[:sorts]

      results = q.result.uniq(&:id)
      page = params[:page] || 1
      per_page = params[:per_page] || Kaminari.config.default_per_page

      Kaminari.paginate_array(results).page(page).per(per_page)
    }
  end
end
