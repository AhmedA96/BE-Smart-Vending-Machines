# frozen_string_literal: true

module Paginable
  extend ActiveSupport::Concern

  private

  def paginate(collection)
    @pagy, records = pagy(collection, items: params[:per_page] || Pagy::DEFAULT[:items])
    records
  end
end
