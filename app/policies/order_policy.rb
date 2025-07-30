# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  class Scope < BaseScope
    def resolve
      if admin?
        scope.all
      elsif user.present?
        scope.where(user_id: user.id).or(scope.where(user_id: nil))
      else
        scope.none
      end
    end
  end

  def index?
    admin? || user.present?
  end

  def show?
    admin? || user_owns_order? || guest_order_allowed?
  end

  def create?
    true
  end

  def new?
    admin?
  end

  def edit?
    admin?
  end

  def update?
    admin? || user_owns_order? || authenticated_user_claiming_guest_order?
  end

  def act_on?
    admin?
  end

  def search?
    admin?
  end

  def reorder?
    user_owns_order?
  end

  private

  def user_owns_order?
    record.user_id == user&.id
  end

  def guest_order_allowed?
    record.guest_order?
  end

  def authenticated_user_claiming_guest_order?
    record.guest_order? && user.present?
  end
end
