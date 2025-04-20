# frozen_string_literal: true

module RansackScope
  extend ActiveSupport::Concern

  included do
    scope :ransack_filter, lambda { |params|
      q = ransack(params[:q] || {})

      q.sorts = params[:sorts] if params[:sorts]

      results = q.result.uniq(&:id)
      items_per_page = params[:per_page] || Pagy::DEFAULT[:items]
      pagy_array(results, page: params[:page], items: items_per_page)
    }
  end
end
