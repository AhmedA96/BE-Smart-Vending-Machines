# frozen_string_literal: true

json.wallet_transaction do
  json.partial! 'wallet_transaction', transaction: @wallet_transaction
end
