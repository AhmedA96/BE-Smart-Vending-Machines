# frozen_string_literal: true

class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable,
         password_length: 8..128

  validates :mobile_number, phone: { possible: true, allow_blank: false }, presence: true,
                            uniqueness: true

  validates :gender, inclusion: { in: %w[male female] }, allow_nil: true
  validates :nationality, inclusion: { in: WORLD_COUNTRIES }, allow_nil: true

  validate :password_complexity
  validate :new_and_old_password_must_be_different

  def password_complexity
    return if password.blank? || password.match?(/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,70}$/)

    errors.add(:password, I18n.t('errors.messages.password_complexity'))
  end

  def new_and_old_password_must_be_different
    return unless encrypted_password_changed? && Devise.secure_compare(encrypted_password, encrypted_password_was)

    errors.add(:new_password, I18n.t('errors.messages.password_must_be_different'))
  end
end
