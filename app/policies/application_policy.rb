# frozen_string_literal: true

module RolseDelegation
  extend ActiveSupport::Concern

  included do
    delegate :super_admin?, :admin?, to: :user, allow_nil: true
  end
end

class ApplicationPolicy
  include RolseDelegation
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  ACTIONS = %i[index? show? create? new? update? edit? destroy?].freeze

  ACTIONS.each do |action|
    define_method(action) do
      super_admin?
    end
  end

  class BaseScope
    include RolseDelegation

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
