# frozen_string_literal: true

# == Schema Information
#
# Table name: mobile_verifications
#
#  id            :bigint           not null, primary key
#  code          :string
#  expired       :boolean          default(FALSE), not null
#  expires_at    :datetime
#  mobile_number :string
#  verified      :boolean          default(FALSE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint
#
# Indexes
#
#  index_mobile_verifications_on_user_id  (user_id)
#
class MobileVerification < ApplicationRecord
  belongs_to :user

  before_create :set_expires_at

  validates :mobile_number, presence: true
  validates :code, presence: true

  scope :active, -> { where(expired: false, verified: false) }
  scope :for_user, ->(user) { where(user: user) }

  def expired?
    expired || expires_at <= Time.zone.now
  end

  def mark_as_expired!
    update!(expired: true)
  end

  private

  def set_expires_at
    self.expires_at ||= 5.minutes.from_now
  end
end
