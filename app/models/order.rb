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
#  machine_id       :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_orders_on_machine_id  (machine_id)
#  index_orders_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (machine_id => machines.id)
#  fk_rails_...  (user_id => users.id)
#
class Order < ApplicationRecord
  include AASM

  belongs_to :user
  belongs_to :machine
  has_many :line_items, dependent: :nullify
  has_many :variants, through: :line_items

  delegate :price_list, to: :machine, allow_nil: true

  validates :number, presence: true

  aasm column: 'status' do
    state :initial, initial: true
    state :pending
    state :dispended

    event :pending do
      transitions from: :initial, to: :pending
    end

    event :dispense do
      transitions from: :pending, to: :dispended
    end
  end

  def self.generate_unique_order_number
    loop do
      random_number = SecureRandom.random_number(1...10_000_000_000)
      order_number = "VNDG#{random_number}"
      return order_number unless Order.exists?(number: order_number)
    end
  end
end
