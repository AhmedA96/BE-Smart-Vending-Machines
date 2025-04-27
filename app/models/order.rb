# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id                 :bigint           not null, primary key
#  completed_at       :datetime
#  deleted_at         :datetime
#  dispense_status    :string
#  items_total        :decimal(10, 2)   default(0.0)
#  machine_response   :jsonb
#  number             :string           not null
#  payment_method     :string
#  status             :string
#  total              :decimal(10, 2)   default(0.0)
#  total_discounts    :decimal(10, 2)   default(0.0)
#  total_tax          :decimal(10, 2)   default(0.0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint           not null
#  vending_machine_id :bigint           not null
#
# Indexes
#
#  index_orders_on_user_id             (user_id)
#  index_orders_on_vending_machine_id  (vending_machine_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (vending_machine_id => vending_machines.id)
#
class Order < ApplicationRecord
  validates :number, :status, presence: true
  belongs_to :user
end
