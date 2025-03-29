# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  class Scope < BaseScope
    def resolve
      if super_admin?
        scope.all
      elsif admin?
        scope.with_role(:admin)
      elsif user
        scope.where(id: user.id)
      else
        scope.none
      end
    end
  end

  def index? = admins?
  def show? = admins?
  def new? = admin?
  def create? = admin?
  def edit? = admin?
  def update? = admin?
  def destroy? = super_admin?

  private

  def admins?
    super_admin? || admin?
  end
end
