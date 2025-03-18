# frozen_string_literal: true

# == Schema Information
#
# Table name: machine_statuses
#
#  id                 :bigint           not null, primary key
#  changed_at         :datetime
#  notes              :text
#  status             :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  vending_machine_id :bigint           not null
#
# Indexes
#
#  index_machine_statuses_on_vending_machine_id  (vending_machine_id)
#
# Foreign Keys
#
#  fk_rails_...  (vending_machine_id => vending_machines.id)
#
class MachineStatus < ApplicationRecord
  belongs_to :vending_machine

  validates :status, inclusion: { in: %w[active inactive maintenance retired] }
end
