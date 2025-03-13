# frozen_string_literal: true

class MachineCategory < ApplicationRecord
  has_many :vending_machines, foreign_key: 'category_id', inverse_of: :category
end
