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
end
