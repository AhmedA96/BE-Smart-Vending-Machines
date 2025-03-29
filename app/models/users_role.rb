# frozen_string_literal: true

# == Schema Information
#
# Table name: users_roles
#
#  role_id :bigint
#  user_id :bigint
#
# Indexes
#
#  index_users_roles_on_role_id              (role_id)
#  index_users_roles_on_user_id              (user_id)
#  index_users_roles_on_user_id_and_role_id  (user_id,role_id)
#
class UsersRole < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :role, optional: false

  def name
    "#{role&.name&.humanize} - #{role&.resource&.name}"
  end
end
