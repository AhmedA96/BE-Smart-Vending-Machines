# frozen_string_literal: true

class CreateMachinePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :machine_payment_methods do |t|
      t.integer :machine_id, index: true
      t.integer :payment_method_id, index: true
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :machine_payment_methods, %i[machine_id payment_method_id],
              name: :index_mach_pay_methods_on_machine_id_and_payment_method_id, unique: true
  end
end
