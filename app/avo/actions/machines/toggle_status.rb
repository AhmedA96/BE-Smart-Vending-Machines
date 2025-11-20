# frozen_string_literal: true

module Avo
  module Actions
    module Machines
      class ToggleStatus < Avo::BaseAction
        self.name = 'Change Machine Status'
        self.message = 'Update the status of selected machine(s)'
        self.confirm_button_label = 'Update Status'
        self.cancel_button_label = 'Cancel'
        def fields
          field :new_status, as: :select,
                             help: 'Select the new status for the machine(s)',
                             options: {
                               'Active' => 'Active',
                               'Inactive' => 'Inactive',
                               'Maintenance' => 'Maintenance',
                               'Retired' => 'Retired'
                             },
                             placeholder: 'Choose status'

          field :notes, as: :textarea,
                        help: 'Add notes about this status change (required for Inactive, Maintenance, or Retired)',
                        placeholder: 'Reason for status change...'
        end

        def handle(query:, fields:, resource:, **_args) # rubocop:disable Lint/UnusedMethodArgument
          new_status = fields[:new_status]
          notes = fields[:notes]

          return validate_fields(new_status, notes) unless valid_input?(new_status, notes)

          updated_count = update_machine_statuses(query, new_status, notes)

          succeed "Successfully updated #{updated_count} machine(s) to #{new_status}"
        end

        private

        def valid_input?(new_status, notes)
          return false if new_status.blank?
          return true if new_status == 'Active'

          notes.present?
        end

        def validate_fields(new_status, notes)
          return error 'Please select a status' if new_status.blank?

          if %w[Inactive Maintenance Retired].include?(new_status) && notes.blank?
            error "Notes are required when setting status to #{new_status}"
          else
            error 'Please select a valid status'
          end
        end

        def update_machine_statuses(query, new_status, notes)
          count = 0

          query.each do |machine|
            create_machine_status(machine, new_status, notes)
            count += 1
          end

          count
        end

        def create_machine_status(machine, status, notes)
          MachineStatus.create!(
            machine: machine,
            status: status,
            notes: notes,
            changed_at: Time.current
          )
        end
      end
    end
  end
end
