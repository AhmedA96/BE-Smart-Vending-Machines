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
#  pick_up_code     :string
#  status           :string
#  total            :decimal(10, 2)   default(0.0)
#  total_discounts  :decimal(10, 2)   default(0.0)
#  total_tax        :decimal(10, 2)   default(0.0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  machine_id       :bigint           not null
#  user_id          :bigint
#
# Indexes
#
#  index_orders_on_machine_id              (machine_id)
#  index_orders_on_user_id                 (user_id)
#  index_orders_on_user_id_and_created_at  (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (machine_id => machines.id)
#  fk_rails_...  (user_id => users.id)
#
class Order < ApplicationRecord
  include AASM

  belongs_to :user, optional: true
  belongs_to :machine
  has_many :line_items, dependent: :nullify
  has_many :variants, through: :line_items
  has_many :payments, dependent: :nullify

  delegate :price_list, to: :machine, allow_nil: true
  delegate :country, to: :machine, allow_nil: true
  delegate :supplier, to: :machine, allow_nil: true

  validates :number, presence: true
  validate :check_item_limit

  # Scopes for guest and user orders
  scope :guest_orders, -> { where(user_id: nil) }
  scope :user_orders, -> { where.not(user_id: nil) }
  scope :cart, -> { where(status: 'cart') }
  scope :completed, -> { where(status: %w[paid dispensed]) }
  scope :expired_carts, lambda { |timeout_minutes = 10|
    where(status: 'cart').where(created_at: ...timeout_minutes.minutes.ago)
  }

  aasm column: 'status' do
    state :cart, initial: true
    state :pending_payment
    state :paid
    state :pending_dispense
    state :dispensed
    state :failed
    state :cancelled

    event :process_payment do
      transitions from: :cart, to: :pending_payment, guard: :user_present?
      after do
        Stock::Reservation.reserve_order!(self)

        payment_successful = Orders::ProcessPayment.call(self, user)

        if payment_successful
          mark_paid!
        else
          fail!
        end
      end
    end

    event :mark_paid do
      transitions from: :pending_payment, to: :paid
      after do
        Stock::Reservation.commit_order!(self)
        generate_pickup_code
      end
    end

    event :start_dispense do
      transitions from: :paid, to: :pending_dispense
    end

    event :complete_dispense do
      transitions from: :pending_dispense, to: :dispensed
      after do
        update(completed_at: Time.current)
      end
    end

    event :fail do
      transitions from: %i[pending_payment paid pending_dispense], to: :failed
      after do
        Stock::Reservation.release_order!(self)
      end
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

  def guest_order?
    user_id.nil?
  end

  def recalculate_totals!
    self.items_total = line_items.sum { |item| item.quantity * item.price }
    save!
  end

  def completed?
    status == 'paid'
  end

  private

  def user_present?
    user_id.present?
  end

  def generate_pickup_code
    Orders::CreatePickupCode.call(self)
  end

  def check_item_limit
    return unless machine&.max_items_per_order

    total_items = line_items.sum(:quantity)
    return unless total_items > machine.max_items_per_order

    errors.add(:base, "Maximum #{machine.max_items_per_order} item allowed per order")
  end
end
