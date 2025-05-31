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
end
