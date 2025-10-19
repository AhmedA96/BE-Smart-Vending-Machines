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
end
