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
  has_many :payments, dependent: :nullify

  delegate :price_list, to: :machine, allow_nil: true
  delegate :country, to: :machine, allow_nil: true
  delegate :supplier, to: :machine, allow_nil: true

  validates :number, presence: true

  aasm column: 'status' do
    state :cart, initial: true
    state :pending_payment
    state :paid
    state :pending_dispense
    state :dispensed
    state :failed
    state :cancelled

    event :process_payment do
      transitions from: :cart, to: :pending_payment
    end

    event :mark_paid do
      transitions from: :pending_payment, to: :paid
      after do
        create_machine_order
      end
    end

    event :start_dispense do
      transitions from: :paid, to: :pending_dispense
      after do
        start_dispense_status_check
      end
    end

    event :complete_dispense do
      transitions from: :pending_dispense, to: :dispensed
      after do
        update(completed_at: Time.current)
      end
    end

    event :fail do
      transitions from: %i[pending_payment paid pending_dispense], to: :failed
    end

    event :cancel do
      transitions from: %i[cart pending_payment], to: :cancelled
    end
  end

  def self.generate_unique_order_number
    loop do
      random_number = SecureRandom.random_number(1...10_000_000_000)
      order_number = "VNDG#{random_number}"
      return order_number unless Order.exists?(number: order_number)
    end
  end

  private

  def create_machine_order
    return unless supplier

    # job to create the order in the machine backend
    Suppliers::CreateMachineOrderJob.perform_async(id)
  end

  def start_dispense_status_check
    return unless supplier

    initial_delay = case supplier.name.downcase
                    when 'reyah'
                      1.minute
                    end

    Suppliers::CheckDispenseStatusJob.perform_in(initial_delay, id)
  end
end
