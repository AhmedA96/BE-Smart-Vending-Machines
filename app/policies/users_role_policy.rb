# frozen_string_literal: true

class UsersRolePolicy < ApplicationPolicy
  class Scope < BaseScope
    def resolve
      if super_admin?
        scope.all
      elsif admin?
        scope.where.not(name: 'super_admin')
      else
        scope.none
      end
    end
  end

  def index?
    super_admin_user?
  end

  def show?
    super_admin_user?
  end

  def new?
    super_admin_user?
  end

  def create?
    super_admin_user?
  end

  def edit?
    super_admin_user?
  end

  def update?
    super_admin_user?
  end

  def destroy?
    super_admin_user?
  end

  private

  def super_admin_user?
    super_admin?
  end
end
