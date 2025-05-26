# frozen_string_literal: true

json.payment_methods @payment_methods do |payment_method|
  json.partial! 'payment_method', payment_method:
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @payment_methods
end
