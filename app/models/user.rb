# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  avatar                 :string
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  date_of_birth          :date
#  deleted_at             :datetime
#  email                  :string
#  email_notification     :boolean          default(TRUE), not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  hashed_password        :string
#  last_active_at         :datetime
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locale                 :string           default("en")
#  locked_at              :datetime
#  mobile_number          :string
#  name                   :string
#  provider               :string
#  qr_code_token          :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  sms_notification       :boolean          default(TRUE), not null
#  uid                    :string
#  unconfirmed_email      :string
#  unlock_token           :string
#  verified               :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  country_id             :bigint
#  profile_id             :bigint
#
# Indexes
#
#  index_users_on_country_id            (country_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_locale                (locale)
#  index_users_on_mobile_number         (mobile_number) UNIQUE
#  index_users_on_qr_code_token         (qr_code_token)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#
class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable,
         password_length: 8..128

  validates :mobile_number,
            phone: { possible: true, allow_blank: false },
            presence: true,
            uniqueness: { case_sensitive: false }

  validate :password_complexity
  validate :new_and_old_password_must_be_different

  has_one :payment_customer, dependent: :destroy
  has_one :wallet, dependent: :destroy

  has_many :orders, dependent: :destroy
  has_many :line_items, through: :orders
  has_many :user_favorites, dependent: :destroy
  has_many :favorite_products, through: :user_favorites, source: :product
  has_many :users_roles, dependent: :destroy
  has_many :mobile_verifications, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :payment_cards, through: :payment_customer

  belongs_to :country, optional: true

  before_create :set_country_from_mobile, if: -> { mobile_number.present? && country.nil? }
  before_create :generate_qr_code_token
  after_create :create_wallet

  def password_complexity
    return if password.blank? || password.match?(/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,70}$/)

    errors.add(:password, I18n.t('errors.messages.password_complexity'))
  end

  def new_and_old_password_must_be_different
    return unless encrypted_password_changed? && Devise.secure_compare(encrypted_password, encrypted_password_was)

    errors.add(:new_password, I18n.t('errors.messages.password_must_be_different'))
  end

  def email_required?
    false
  end

  def will_save_change_to_email?
    false
  end

  def email_changed?
    false
  end

  def self.authenticate(mobile_number, password)
    user = find_by(mobile_number:)
    user if user&.valid_password?(password)
  end

  def loaded_roles
    @loaded_roles ||= roles.to_a
  end

  def role?(role_name)
    loaded_roles.any? { |role| role.name == role_name.to_s }
  end

  ROLES.each do |role|
    define_method :"#{role}?" do
      instance_variable_set(:"@#{role}", load_role(role))
    end
  end

  def load_role(role)
    role?(role)
  end

  def resource_title
    name.presence || email || "User/#{id}"
  end

  def most_ordered_products(limit: 10)
    Product.joins(variants: { line_items: :order })
           .where(orders: { user_id: id })
           .group('products.id')
           .order('COUNT(line_items.id) DESC')
           .limit(limit)
           .select('products.*, COUNT(line_items.id) as order_count')
  end

  def recently_ordered_products(limit: 5)
    Product.joins(variants: { line_items: :order })
           .where(orders: { user_id: id })
           .where(products: { deleted_at: nil })
           .select('DISTINCT ON (products.id) products.*, orders.created_at AS order_created_at')
           .order('products.id, orders.created_at DESC')
           .limit(limit)
  end

  private

  def create_wallet
    create_wallet!(balance: 0.0) if wallet.blank?
  end

  def generate_qr_code_token
    self.qr_code_token = loop do
      part1 = SecureRandom.alphanumeric(4).upcase
      part2 = SecureRandom.alphanumeric(4).upcase
      part3 = SecureRandom.alphanumeric(4).upcase
      token = "#{part1}-#{part2}-#{part3}"
      break token unless User.exists?(qr_code_token: token)
    end
  end

  def set_country_from_mobile
    parsed = Phonelib.parse(mobile_number)
    if parsed.valid?
      self.country = Country.find_by(iso2: parsed.country)
      Rails.logger.info "Setting country #{country&.iso2} for #{mobile_number}"
    else
      Rails.logger.warn "Invalid phone number #{mobile_number}"
    end
  end
end
