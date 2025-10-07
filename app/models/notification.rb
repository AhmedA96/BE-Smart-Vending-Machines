# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id                :bigint           not null, primary key
#  body              :text             not null
#  metadata          :jsonb
#  notifiable_type   :string
#  notification_type :string           not null
#  read              :boolean          default(FALSE)
#  read_at           :datetime
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  notifiable_id     :bigint
#  user_id           :bigint           not null
#
# Indexes
#
#  index_notifications_on_notifiable              (notifiable_type,notifiable_id)
#  index_notifications_on_notification_type       (notification_type)
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
end
