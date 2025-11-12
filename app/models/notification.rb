# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id                 :bigint           not null, primary key
#  body               :text             not null
#  metadata           :jsonb
#  notifiable_type    :string
#  notification_type  :string           not null
#  read               :boolean          default(FALSE)
#  read_at            :datetime
#  title              :string           not null
#  translation_key    :string
#  translation_params :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  notifiable_id      :bigint
#  user_id            :bigint           not null
#
# Indexes
#
#  index_notifications_on_notifiable              (notifiable_type,notifiable_id)
#  index_notifications_on_notification_type       (notification_type)
#  index_notifications_on_translation_key         (translation_key)
#  index_notifications_on_user_id                 (user_id)
#  index_notifications_on_user_id_and_created_at  (user_id,created_at)
#  index_notifications_on_user_id_and_read        (user_id,read)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  TYPES = {
    order_payment: 'order_payment',
    order_ready: 'order_ready',
    order_dispensed: 'order_dispensed',
    order_failed: 'order_failed',
    machine_offline: 'machine_offline',
    promotion: 'promotion'
  }.freeze

  validates :notification_type, presence: true, inclusion: { in: TYPES.values }
  validates :title, :body, presence: true
  validates :translation_key, presence: true

  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }

  def translated_title
    I18n.t("#{translation_key}.title", **resolved_params, default: title)
  end

  def translated_body
    I18n.t("#{translation_key}.body", **resolved_params, default: body)
  end

  def mark_as_read!
    update(read: true, read_at: Time.current)
  end

  def mark_as_unread!
    update(read: false, read_at: nil)
  end

  private

  def resolved_params
    params = translation_params.symbolize_keys

    if params[:machine_id].present?
      machine = Machine.find_by(id: params[:machine_id])
      params[:machine_name] = machine&.name
    end
    params
  end
end
