# frozen_string_literal: true

# == Schema Information
#
# Table name: vendors
#
#  id             :bigint           not null, primary key
#  address        :text
#  contact_person :string
#  email          :string
#  name           :string
#  phone_number   :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Vendor < ApplicationRecord
  has_many :vending_machines

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone_number, format: { with: /\A\+?[0-9\s\-()]*\z/ }, allow_blank: true
  validates :address, length: { maximum: 255 }, allow_blank: true
  validates :contact_person, length: { maximum: 100 }, allow_blank: true
end
