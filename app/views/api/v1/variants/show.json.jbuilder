# frozen_string_literal: true

json.product do
  json.partial! 'variant', product: @variant
end
