# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_customers
#
#  id                      :bigint           not null, primary key
#  payment_customer_number :string           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  user_id                 :integer
#
# Indexes
#
#  index_payment_customers_on_payment_customer_number_and_user_id  (payment_customer_number,user_id) UNIQUE
#
class PaymentCustomer < ApplicationRecord
  belongs_to :user, optional: false

  validates :payment_customer_number, presence: true
  validates :payment_customer_number, uniqueness: { scope: :user_id }
end
