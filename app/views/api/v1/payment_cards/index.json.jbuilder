# frozen_string_literal: true

json.payment_cards @payment_cards do |payment_card|
  json.partial! 'payment_card', payment_card:
end
