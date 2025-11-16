# frozen_string_literal: true

json.extract! order, :id, :number, :user_id, :machine_id, :status, :pick_up_code,
              :items_total, :created_at, :completed_at, :dispense_status

json.currency order.country.currency

if order.machine.present?
  json.machine do
    json.id order.machine.id
    json.name order.machine.presentation
    json.location do
      json.id order.machine.location.id
      json.name order.machine.location.name
    end
    json.image do
      json.url(order.machine.image.attached? ? url_for(order.machine.image) : nil)
    end
  end
end

last_payment = order.payments.last

if last_payment.present?
  json.payment do
    json.id last_payment.id
    json.status last_payment.status
    json.amount last_payment.amount
    json.payment_method last_payment.payment_method
    json.created_at last_payment.created_at
  end
end
