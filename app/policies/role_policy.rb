# frozen_string_literal: true

class RolePolicy < ApplicationPolicy
  class Scope < BaseScope
    def resolve
      if admin?
        scope.all
      else
        scope.none
      end
    end
  end

  def index? = admin?
  def show? = admin?
  def new? = admin?
  def create? = admin?
  def edit? = admin?
  def update? = admin?
  def destroy? = admin?
  def search? = true
end
