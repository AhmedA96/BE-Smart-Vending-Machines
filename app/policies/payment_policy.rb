# frozen_string_literal: true

class PaymentPolicy < ApplicationPolicy
  class Scope < BaseScope
    def resolve
      if admin?
        scope.all
      else
        scope.none
      end
    end
  end

  def index? = admins?
  def show? = admins?
  def create? = true
  def new? = admins?
  def edit? = admins?
  def update? = admins?
  def act_on? = admins?
  def search? = admins?
  def refund? = admins?
end
