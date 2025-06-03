# frozen_string_literal: true

module TapPayments
  class SavePaymentResult
    def self.call(params)
      token_id = params&.dig('source', 'id')
      payment = Payment.find_by(token_id:)
      return false unless payment

      unless params&.dig('status') == 'CAPTURED'
        payment.failed!
        payment.update!(message: params&.dig('response', 'message'))
        return false
      end

      payment.complete!
      TapPayments::SaveChargeRecord.call(params, payment.order&.user&.payment_customer&.id, payment.id)
      payment.completed?
    end
  end
end
