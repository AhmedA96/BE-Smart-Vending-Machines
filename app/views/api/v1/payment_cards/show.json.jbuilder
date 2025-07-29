# frozen_string_literal: true

json.payment_card do
  json.partial! 'payment_card', payment_card: @payment_card
end
