# frozen_string_literal: true

# == Schema Information
#
# Table name: devices
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(TRUE)
#  last_used_at :datetime
#  metadata     :jsonb
#  platform     :string           not null
#  token        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_devices_on_token                 (token) UNIQUE
#  index_devices_on_user_id               (user_id)
#  index_devices_on_user_id_and_active    (user_id,active)
#  index_devices_on_user_id_and_platform  (user_id,platform)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Device < ApplicationRecord
  belongs_to :user

  PLATFORMS = {
    ios: 'ios',
    android: 'android',
    web: 'web'
  }.freeze

  validates :token, presence: true, uniqueness: true
  validates :platform, presence: true, inclusion: { in: PLATFORMS.values }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :recently_used, -> { where('last_used_at > ?', 30.days.ago) }

  before_validation :normalize_platform

  def deactivate!
    update(active: false)
  end

  def activate!
    update(active: true, last_used_at: Time.current)
  end

  private

  def normalize_platform
    self.platform = platform&.downcase
  end
end
