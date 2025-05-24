# frozen_string_literal: true

# == Schema Information
#
# Table name: contact_us_requests
#
#  id           :bigint           not null, primary key
#  company_name :string
#  email        :string
#  full_name    :string
#  phone_number :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class ContactUsRequest < ApplicationRecord
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone_number, phone: { possible: true, allow_blank: false }, presence: true
  validates :full_name, :company_name, presence: true
end
