# frozen_string_literal: true

# == Schema Information
#
# Table name: users_roles
#
#  key     :bigint           not null, primary key
#  role_id :bigint
#  user_id :bigint
#
# Indexes
#
#  index_unique_user_role        (user_id,role_id) UNIQUE
#  index_users_roles_on_role_id  (role_id)
#
class UsersRole < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :role, optional: false

  def name
    "#{role&.name&.humanize} - #{role&.resource&.name}"
  end
end
