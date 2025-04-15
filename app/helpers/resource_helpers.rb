# frozen_string_literal: true

module ResourceHelpers
  include Pundit::Authorization

  delegate :admin?, to: :current_user

  def limited_field(name, **, &)
    field(name, attach_scope: -> { query.limit(1) }, **, &)
  end
end
