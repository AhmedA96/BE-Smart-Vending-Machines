# frozen_string_literal: true

module RansackScope
  extend ActiveSupport::Concern

  included do
    scope :ransack_filter, lambda { |params|
      q = ransack(params[:q] || {})
      q.sorts = params[:sorts] if params[:sorts]
      q.result.distinct
    }
  end
end
