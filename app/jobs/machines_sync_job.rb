# frozen_string_literal: true

class MachinesSyncJob < ApplicationJob
  queue_as :machine_status_sync

  RATE_LIMIT_DELAY = 1.2

  def perform
    machines = Machine.active
                      .joins(:supplier)
                      .where(suppliers: { name: 'vendlife' })
                      .where.not(machineuuid: nil)
                      .includes(:supplier)

    machines.each_with_index do |machine, index|
      sync_machine_status(machine)

      sleep(RATE_LIMIT_DELAY) if index < machines.count - 1
    end
  end

  private

  def sync_machine_status(machine)
    service = build_machine_manager(machine)
    service.sync_machine_data(machine)
  end

  def build_machine_manager(machine)
    service = machine.supplier.api_service
    service.authenticate
    service
  end
end
