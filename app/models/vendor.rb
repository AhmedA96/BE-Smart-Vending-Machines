# frozen_string_literal: true

class Vendor < ApplicationRecord
  has_many :vending_machines
end
