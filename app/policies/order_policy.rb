# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
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
  def create? = true
  def new? = admin?
  def edit? = admin?
  def update? = admin?
  def act_on? = admin?
  def search? = admin?
end
