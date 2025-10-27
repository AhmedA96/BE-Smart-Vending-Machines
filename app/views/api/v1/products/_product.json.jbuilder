# frozen_string_literal: true

json.extract! product, :id, :name, :presentation, :description, :status, :category_ids
if @machine.present?
  json.machine do
    json.extract! @machine, :id, :name, :category_id
  end
end

json.images product.images.attached? ? product.images.map { |img| url_for(img) } : []
