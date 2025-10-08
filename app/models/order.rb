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
  scope :completed, -> { where(status: %w[completed dispensed]) }
  scope :expired_carts, lambda { |timeout_minutes = 10|
    where(status: 'cart').where(created_at: ...timeout_minutes.minutes.ago)
  }

  aasm column: 'status' do
    state :cart, initial: true
    state :payment
    state :completed
    state :dispensed

    event :process_payment do
      transitions from: :cart, to: :payment, guard: :user_present?
      after do
        Stock::Reservation.reserve_order!(self)

        payment_successful = Orders::ProcessPayment.call(self, user)

        if payment_successful
          mark_completed!
        else
          return_to_cart!
        end
        notify_payment_initiated
      end
    end

    event :mark_completed do
      transitions from: :payment, to: :completed
      after do
        Stock::Reservation.commit_order!(self)
        generate_pickup_code
        notify_order_ready
      end
    end

    event :return_to_cart do
      transitions from: :payment, to: :cart
      after do
        Stock::Reservation.release_order!(self)
      end
    end

    event :mark_dispensed do
      transitions from: :completed, to: :dispensed
      after do
        update(dispense_status: 'dispensed')
        notify_order_dispensed
      end
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
    status == 'completed'
  end

  def ensure_machine_online?
    return false if machine.blank?

    service = Suppliers::VendlifeService.new(machine.supplier)
    response = service.get_machine_status(machine.machineuuid)

    status = response.dig('data', 0, 'netStat')
    status == 1
  rescue StandardError => e
    Rails.logger.error("Machine status check failed: #{e.message}")
    false
  end

  def last_pending_credit_payment
    payments.with_method('credit_card').pending.order(created_at: :desc).first
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

  def notify_payment_initiated
    NotificationService::OrderNotifications.new(self).payment_initiated
  end

  def notify_order_ready
    NotificationService::OrderNotifications.new(self).ready
  end

  def notify_order_dispensed
    NotificationService::OrderNotifications.new(self).dispensed
  end
end
