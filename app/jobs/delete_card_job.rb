# frozen_string_literal: true

class DeleteCardJob
  include Sidekiq::Worker
  sidekiq_options queue: :delete_card, retry: 2

  def perform(card_id, customer_number)
    TapPayments::DeleteCard.call(card_id, customer_number)
  end
end
