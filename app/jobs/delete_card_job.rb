# frozen_string_literal: true

class DeleteCardJob < ApplicationJob
  queue_as :delete_card
  retry_on StandardError, wait: :exponentially_longer, attempts: 2

  def perform(card_id, customer_number)
    TapPayments::DeleteCard.call(card_id, customer_number)
  end
end
