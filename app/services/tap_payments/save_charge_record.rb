# frozen_string_literal: true

module TapPayments
  class SaveChargeRecord
    def self.call(params, payment_customer_id, payment_id)
      charge = PaymentTransaction.find_or_create_by!(
        payment_customer_id:,
        payment_id:,
        charge_id: params['id']
      )

      TapPayments::SaveChargeStatusRecord.call(params, charge.id)
      charge
    end
  end
end
