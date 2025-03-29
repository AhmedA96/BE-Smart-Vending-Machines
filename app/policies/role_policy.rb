# frozen_string_literal: true

class RolePolicy < ApplicationPolicy
  class Scope < BaseScope
    def resolve
      if super_admin?
        scope.all
      elsif admin?
        scope.where.not(name: 'super_admin')
      end
    end
  end

  def index? = admins?
  def show? = admins?
  def new? = admins?
  def create? = admins?
  def edit? = admins?
  def update? = admins?
  def destroy? = admins?
  def search? = true

  private

  def admins?
    user.super_admin? || user.admin?
  end
end
