# frozen_string_literal: true

json.top_up_transaction do
  json.partial! 'wallet_refill', wallet_refill: @wallet_refill
end
