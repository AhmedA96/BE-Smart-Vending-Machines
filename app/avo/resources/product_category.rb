# frozen_string_literal: true

module Avo
  module Resources
    class ProductCategory < Avo::BaseResource
      include ResourceHelpers

      self.includes = %i[]
      self.search = {
        query: lambda {
          query.ransack(id_eq: params[:q], product_name_cont: params[:q], category_name_cont: params[:q],
                        m: 'or').result(distinct: false)
        }
      }

      def fields
        field :id, as: :id
        field :product, as: :belongs_to, searchable: true
        field :category, as: :belongs_to, searchable: true
        field :name, as: :text, only_on: :index, hide_on: :forms
        field :created_at, as: :date_time, readonly: true,  hide_on: %i[index edit new]
        field :updated_at, as: :date_time, readonly: true,  hide_on: %i[index edit new]
      end
    end
  end
end
