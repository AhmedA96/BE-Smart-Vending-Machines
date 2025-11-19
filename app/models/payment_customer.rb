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
#  index_payment_customers_on_payment_customer_number  (payment_customer_number) UNIQUE
#  index_payment_customers_on_user_id                  (user_id) UNIQUE
#
class PaymentCustomer < ApplicationRecord
  belongs_to :user, optional: false
  has_many :payment_cards, dependent: :destroy
  has_many :payment_transactions, dependent: :destroy

  validates :payment_customer_number, presence: true, uniqueness: true
  validates :user_id, uniqueness: true
end
