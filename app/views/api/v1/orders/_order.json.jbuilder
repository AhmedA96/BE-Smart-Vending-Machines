# frozen_string_literal: true

json.extract! order, :id, :number, :user_id, :machine_id, :status, :pick_up_code, :items_total, :created_at

if order.machine.present?
  json.machine do
    json.id order.machine.id
    json.name order.machine.name
    json.location do
      json.id order.machine.location.id
      json.name order.machine.location.name
    end
  end
end

json.payments order.payments.completed do |payment|
  json.id payment.id
  json.status payment.status
  json.amount payment.amount
  json.payment_method payment.payment_method
  json.created_at payment.created_at
end
