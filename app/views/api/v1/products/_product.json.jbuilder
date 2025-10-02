# frozen_string_literal: true

json.extract! product, :id, :name, :presentation, :description, :status
json.images product.images.attached? ? product.images.map { |img| url_for(img) } : []
