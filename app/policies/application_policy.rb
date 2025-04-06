# frozen_string_literal: true

module RolesDelegation
  extend ActiveSupport::Concern

  included do
    delegate :admin?, to: :user, allow_nil: true
  end
end

class ApplicationPolicy
  include RolesDelegation
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  ACTIONS = %i[index? show? create? new? update? edit? destroy?].freeze

  ACTIONS.each do |action|
    define_method(action) do
      admin?
    end
  end

  class BaseScope
    include RolesDelegation

    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "#{self.class} must implement #resolve"
    end
  end
end
