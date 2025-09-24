# frozen_string_literal: true

json.transactions do
  json.array! @wallet_transactions do |transaction|
    json.partial! 'wallet_transaction', transaction:
  end
end

json.pagination do
  json.partial! 'api/v1/shared/pagination', collection: @wallet_transactions
end
