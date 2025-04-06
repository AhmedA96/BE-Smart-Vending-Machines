# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  class Scope < BaseScope
    def resolve
      if admin?
        scope.all
      elsif user
        scope.where(id: user.id)
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
end
