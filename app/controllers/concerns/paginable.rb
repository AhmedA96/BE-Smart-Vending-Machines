# frozen_string_literal: true

module Paginable
  extend ActiveSupport::Concern

  private

  def paginate(collection)
    @pagy, records = pagy(collection, limit: params[:per_page] || Pagy::DEFAULT[:limit])
    records
  end
end
