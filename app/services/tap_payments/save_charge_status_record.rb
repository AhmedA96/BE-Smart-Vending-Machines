# frozen_string_literal: true

module TapPayments
  class SaveChargeStatusRecord
    def self.call(params, payment_transaction_id)
      transaction_url = params['transaction'].present? ? params['transaction']['url'] : nil
      transaction_created_at = params['transaction'].present? ? params['transaction']['created'] : nil

      status = PaymentStatus.find_or_create_by!(
        payment_transaction_id: payment_transaction_id,
        status: params['status']
      )

      status.update!(
        transaction_url:,
        transaction_created_at:
      )
      status
    end
  end
end
