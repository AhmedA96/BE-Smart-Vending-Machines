# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_methods
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(TRUE), not null
#  description  :string
#  name         :string           not null
#  presentation :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class PaymentMethod < ApplicationRecord
  validates :name, presence: true, inclusion: { in: PAYMENT_METHODS.values }
end
