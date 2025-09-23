# frozen_string_literal: true

json.id payment_method.id
json.name payment_method.name
json.presentation payment_method.presentation
json.description payment_method.description
json.active payment_method.active
json.updated_at payment_method.updated_at
json.created_at payment_method.created_at

if payment_method.image.attached?
  json.image url_for(payment_method.image)
else
  json.image nil
end
