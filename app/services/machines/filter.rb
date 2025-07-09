# frozen_string_literal: true

module Machines
  class Filter
    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @location_id = params[:location_id]
      @category_id = params[:category_id]
      @brand_id = params[:brand_id]
    end

    def call
      scope = Machine.all
      scope = scope.where(location_id: @location_id) if @location_id.present?
      scope = scope.where(category_id: @category_id) if @category_id.present?

      if @brand_id.present?
        scope = scope
                .joins(machine_items: { variant: :product })
                .where(products: { brand_id: @brand_id })
      end

      scope.merge(Machine.active).distinct
    end
  end
end
