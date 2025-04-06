# frozen_string_literal: true

class UsersRolePolicy < ApplicationPolicy
  class Scope < BaseScope
    def resolve
      if admin?
        scope.all
      else
        scope.none
      end
    end
  end

  def index?
    admin_user?
  end

  def show?
    admin_user?
  end

  def new?
    admin_user?
  end

  def create?
    admin_user?
  end

  def edit?
    admin_user?
  end

  def update?
    admin_user?
  end

  def destroy?
    admin_user?
  end

  private

  def admin_user?
    admin?
  end
end
