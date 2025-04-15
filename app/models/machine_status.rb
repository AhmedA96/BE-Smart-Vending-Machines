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

  validates :status, presence: true, inclusion: { in: %w[Active Inactive Maintenance Retired] }

  after_create :update_vending_machine_status

  private

  def update_vending_machine_status
    vending_machine.update(status: status)
  end
end
