# frozen_string_literal: true

class MachineStatus < ApplicationRecord
  belongs_to :vending_machine

  validates :status, inclusion: { in: %w[active inactive maintenance retired] }
end
