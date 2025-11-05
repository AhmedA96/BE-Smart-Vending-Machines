# frozen_string_literal: true

json.extract! @current_user, :id, :name, :email, :mobile_number, :avatar, :date_of_birth,
              :locale, :verified, :qr_code_token
json.wallet @current_user.wallet
json.customer_number @current_user.payment_customer.payment_customer_number if @current_user.payment_customer.present?
