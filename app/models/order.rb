# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id               :bigint           not null, primary key
#  completed_at     :datetime
#  deleted_at       :datetime
#  dispense_status  :string
#  items_total      :decimal(10, 2)   default(0.0)
#  machine_response :jsonb
#  number           :string           not null
#  payment_method   :string
#  status           :string
#  total            :decimal(10, 2)   default(0.0)
#  total_discounts  :decimal(10, 2)   default(0.0)
#  total_tax        :decimal(10, 2)   default(0.0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class Order < ApplicationRecord
end
