# frozen_string_literal: true

# == Schema Information
#
# Table name: machine_statuses
#
#  id         :bigint           not null, primary key
#  changed_at :datetime
#  notes      :text
#  status     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  machine_id :bigint           not null
#
# Indexes
#
#  index_machine_statuses_on_machine_id  (machine_id)
#
# Foreign Keys
#
#  fk_rails_...  (machine_id => machines.id)
#
class MachineStatus < ApplicationRecord
  belongs_to :machine

  validates :status, presence: true, inclusion: { in: %w[Active Inactive Maintenance Retired] }

  after_create :update_machine_status

  private

  def update_machine_status
    machine.update(status: status)
  end
end
