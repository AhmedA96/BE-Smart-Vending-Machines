# frozen_string_literal: true

class CreateMachineStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :machine_statuses do |t|
      t.references :vending_machine, null: false, foreign_key: true
      t.string :status
      t.datetime :changed_at
      t.text :notes

      t.timestamps
    end
  end
end
